import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/community_models.dart';
import '../models/twitch_message.dart';
import '../services/community_repository.dart';
import '../services/obs_websocket_client.dart';
import '../services/overlay_server.dart';

/// Plantilla de comando parametrizado para la botonera del Estudio Remoto.
class ParameterizedCommandTemplate {
  const ParameterizedCommandTemplate({
    required this.id,
    required this.label,
    required this.template,
    required this.category,
  });

  final String id;
  final String label;
  final String template; // Contiene [usuario], [canal] o [mensaje]
  final String category; // 'usuario' | 'canal' | 'mensaje' | 'moderacion'
}

/// Controlador del Estudio de Control Remoto Puro y CRM de Comunidad (Meta 2).
///
/// Cumple el ajuste Argon M2-A: la ingesta de chat en vivo ([ingestLiveChatMessage])
/// actualiza exclusivamente el estado en memoria (0 escrituras inmediatas a
/// Firestore), mientras que las acciones manuales del streamer en la UI
/// realizan exactamente 1 escritura dirigida en [CommunityRepository].
class RemoteStudioController extends ChangeNotifier {
  RemoteStudioController({
    CommunityRepository? repository,
    OverlayServer? overlayServer,
    bool enablePeriodicFlush = false,
  })  : _repository = repository ?? CommunityRepository(),
        _overlayServer = overlayServer {
    _seedDefaultCommunityPresets();
    if (enablePeriodicFlush) {
      _flushTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) => flushDirtyUsers(),
      );
    }
  }

  final CommunityRepository _repository;
  OverlayServer? _overlayServer;
  ObsWebSocketClient? _obsClient;
  String _activeObsScene = '';

  CommunityRepository get repository => _repository;

  final Map<String, CommunityUser> _users = {};
  final Map<String, List<CommunityMessage>> _messagesByUser = {};
  final List<CommunityMessage> _recentChatMessages = [];
  final List<SmsInboxItem> _smsInbox = [];
  final Set<String> _dirtyUserIds = {};

  RemoteStudioState _studioState = RemoteStudioState(
    updatedAt: DateTime.now(),
  );

  // Búsqueda con debounce de 250ms y filtros CRM
  Timer? _searchDebounce;
  Timer? _flushTimer;
  String _searchQuery = '';
  String _activeFilter = 'todos'; // 'todos' | 'twitch' | 'youtube' | 'vip' | 'mod'

  // Estado de fuentes OBS de la escena activa
  List<ObsSourceItem> _obsSources = [];
  String _obsSourcesSearch = '';
  bool _loadingObsSources = false;

  // Favoritos de comandos rápidos
  final Set<String> _favoriteCommands = {};


  /// Presets canónicos de la comunidad para el asistente parametrizado.
  static const List<String> canonicalUsers = [
    'apliarte',
    'erbolamm',
    'javier',
    'mod_oficial',
  ];

  static const List<String> canonicalChannels = [
    'apliarte',
    'erbolamm',
    'flutterdev',
  ];

  static const List<String> canonicalMessages = [
    '¡Bienvenidos al directo! Dejad vuestras dudas en el chat.',
    'Recordad que podéis enviar un mensaje destacado con !sms <texto>.',
    'Volvemos en 5 minutos, no os vayáis.',
  ];

  static const List<ParameterizedCommandTemplate> commandTemplates = [
    ParameterizedCommandTemplate(
      id: 'so_user',
      label: 'Shoutout (!so [usuario])',
      template: '!so [usuario]',
      category: 'usuario',
    ),
    ParameterizedCommandTemplate(
      id: 'shoutout_user',
      label: 'Shoutout Oficial (/shoutout [usuario])',
      template: '/shoutout [usuario]',
      category: 'usuario',
    ),
    ParameterizedCommandTemplate(
      id: 'greet_user',
      label: 'Saludo directo (@[usuario] [mensaje])',
      template: '@[usuario] [mensaje]',
      category: 'usuario',
    ),
    ParameterizedCommandTemplate(
      id: 'raid_channel',
      label: 'Lanzar Raid (/raid [canal])',
      template: '/raid [canal]',
      category: 'canal',
    ),
    ParameterizedCommandTemplate(
      id: 'announce_msg',
      label: 'Anuncio destacado (/announce [mensaje])',
      template: '/announce [mensaje]',
      category: 'mensaje',
    ),
  ];

  void attachServices({
    OverlayServer? overlayServer,
    ObsWebSocketClient? obsClient,
    String? channelId,
    String? activeObsScene,
  }) {
    if (overlayServer != null) {
      _overlayServer = overlayServer;
    }
    if (obsClient != null) {
      _obsClient = obsClient;
    }
    if (channelId != null && channelId.trim().isNotEmpty) {
      _repository.setChannelId(channelId);
    }
    if (activeObsScene != null && activeObsScene != _activeObsScene) {
      _activeObsScene = activeObsScene;
    }
  }

  void _seedDefaultCommunityPresets() {
    final now = DateTime.now();
    final defaults = [
      CommunityUser(
        id: CommunityUser.buildId('twitch', 'apliarte'),
        plataforma: 'twitch',
        usuario: 'apliarte',
        nombreVisible: 'ApliArte',
        rol: 'admin',
        esSuscriptor: true,
        vozConfig: TtsVoiceCatalog.byId('locutor').toConfig(),
        notasContexto: 'Canal creador de ApliArte TTS',
        sugerenciaSaludo: '¡Bienvenido maestro @apliarte!',
        totalMensajes: 1,
        primerMensajeEn: now,
        ultimoMensajeEn: now,
        actualizadoEn: now,
        ultimoTexto: 'Estudio remoto listo.',
        ultimaFechaHora: _formatTime(now),
      ),
    ];
    for (final u in defaults) {
      _users[u.id] = u;
    }
  }

  // ─── Getters de estado ────────────────────────────────────────────────────

  RemoteStudioState get studioState => _studioState;
  String get searchQuery => _searchQuery;
  String get activeFilter => _activeFilter;
  List<SmsInboxItem> get smsInbox => List.unmodifiable(_smsInbox);
  List<CommunityMessage> get recentChatMessages =>
      List.unmodifiable(_recentChatMessages);
  Set<String> get favoriteCommands => Set.unmodifiable(_favoriteCommands);
  bool get loadingObsSources => _loadingObsSources;
  String get obsSourcesSearch => _obsSourcesSearch;
  String get activeObsScene => _activeObsScene;

  List<CommunityUser> get allUsers {
    final list = _users.values.toList();
    list.sort((a, b) => b.ultimoMensajeEn.compareTo(a.ultimoMensajeEn));
    return list;
  }

  List<CommunityUser> get filteredUsers {
    final q = _searchQuery.trim().toLowerCase();
    return allUsers.where((u) {
      switch (_activeFilter) {
        case 'twitch':
          if (u.plataforma != 'twitch') return false;
          break;
        case 'youtube':
          if (u.plataforma != 'youtube') return false;
          break;
        case 'vip':
          if (u.rol != 'vip' && !u.esSuscriptor) return false;
          break;
        case 'mod':
          if (u.rol != 'mod' && u.rol != 'admin') return false;
          break;
      }
      if (q.isEmpty) return true;
      return u.usuario.toLowerCase().contains(q) ||
          u.nombreVisible.toLowerCase().contains(q) ||
          u.notasContexto.toLowerCase().contains(q) ||
          u.ultimoTexto.toLowerCase().contains(q);
    }).toList();
  }

  List<ObsSourceItem> get filteredObsSources {
    final q = _obsSourcesSearch.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_obsSources);
    return _obsSources
        .where((s) => s.sourceName.toLowerCase().contains(q))
        .toList();
  }

  CommunityUser? getUser(String platformOrRawId, [String? username]) {
    final id = username != null
        ? CommunityUser.buildId(platformOrRawId, username)
        : CommunityUser.normalizeRawId(platformOrRawId);
    return _users[id];
  }

  List<CommunityMessage> getMessagesForUser(String userId) {
    final normalized = CommunityUser.normalizeRawId(userId);
    final list = _messagesByUser[normalized];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  // ─── Hidratación inicial desde Firestore (bajo demanda) ───────────────────

  Future<void> loadFromRepository() async {
    final remoteUsers = await _repository.fetchUsers();
    for (final u in remoteUsers) {
      _users[u.id] = u;
    }
    final remoteSms = await _repository.fetchSmsInbox();
    if (remoteSms.isNotEmpty) {
      _smsInbox
        ..clear()
        ..addAll(remoteSms);
    }
    final remoteState = await _repository.fetchStudioState();
    if (remoteState != null) {
      _studioState = remoteState;
    }
    notifyListeners();
  }

  Future<void> loadUserMessagesFromRepository(String userId) async {
    final normalized = CommunityUser.normalizeRawId(userId);
    final remoteMsgs = await _repository.fetchUserMessages(normalized);
    if (remoteMsgs.isNotEmpty) {
      _messagesByUser[normalized] = remoteMsgs.take(50).toList();
      notifyListeners();
    }
  }

  // ─── Ingesta en vivo con control estricto de costes (Argon M2-A) ──────────

  /// Procesa un mensaje de chat en directo en memoria (0 escrituras a Firestore).
  void ingestLiveChatMessage(
    TwitchChatMessage msg, {
    String platform = 'twitch',
  }) {
    final now = msg.timestamp;
    final cleanPlatform = platform.toLowerCase().trim();
    final userId = CommunityUser.buildId(cleanPlatform, msg.username);
    final effectiveMsgId = msg.id.isNotEmpty
        ? msg.id
        : '${cleanPlatform}_${userId}_${msg.message}_${now.millisecondsSinceEpoch}';

    // Evitar procesar mensajes duplicados (mismo ID de mensaje ya ingestado)
    if (_recentChatMessages.any((m) => m.id == effectiveMsgId)) {
      return;
    }

    final timeStr = _formatTime(now);
    final existing = _users[userId];

    String inferredRole = existing?.rol ?? 'normal';
    if (msg.isBroadcaster) {
      inferredRole = 'admin';
    } else if (msg.isMod && inferredRole == 'normal') {
      inferredRole = 'mod';
    } else if (msg.isVip && inferredRole == 'normal') {
      inferredRole = 'vip';
    }

    final updatedUser = (existing ??
            CommunityUser(
              id: userId,
              plataforma: cleanPlatform,
              usuario: msg.username.toLowerCase().trim(),
              nombreVisible: msg.displayName.isNotEmpty
                  ? msg.displayName
                  : msg.username,
              rol: inferredRole,
              esSuscriptor: msg.isSub,
              primerMensajeEn: now,
              ultimoMensajeEn: now,
              actualizadoEn: now,
            ))
        .copyWith(
      nombreVisible: msg.displayName.isNotEmpty
          ? msg.displayName
          : (existing?.nombreVisible ?? msg.username),
      rol: inferredRole,
      esSuscriptor: msg.isSub || (existing?.esSuscriptor ?? false),
      totalMensajes: (existing?.totalMensajes ?? 0) + 1,
      ultimoMensajeEn: now,
      actualizadoEn: now,
      ultimoTexto: msg.message,
      ultimaFechaHora: timeStr,
    );

    _users[userId] = updatedUser;
    _dirtyUserIds.add(userId);

    final communityMsg = CommunityMessage(
      id: effectiveMsgId,
      usuarioId: userId,
      plataforma: cleanPlatform,
      usuario: updatedUser.usuario,
      nombreVisible: updatedUser.nombreVisible,
      texto: msg.message,
      color: msg.tags['color']?.isNotEmpty == true
          ? msg.tags['color']!
          : '#5ECEF5',
      timestamp: now,
      fechaHora: timeStr,
    );

    final userHistory = _messagesByUser.putIfAbsent(userId, () => []);
    userHistory.insert(0, communityMsg);
    if (userHistory.length > 50) {
      userHistory.removeRange(50, userHistory.length);
    }

    _recentChatMessages.insert(0, communityMsg);
    if (_recentChatMessages.length > 100) {
      _recentChatMessages.removeRange(100, _recentChatMessages.length);
    }

    // Comandos especiales del Estudio (!sms y !contexto)
    final trimmed = msg.message.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('!sms ')) {
      final smsText = trimmed.substring(5).trim();
      if (smsText.isNotEmpty) {
        final smsItem = SmsInboxItem(
          id: 'sms_${now.microsecondsSinceEpoch}',
          usuario: updatedUser.usuario,
          nombreVisible: updatedUser.nombreVisible,
          texto: smsText,
          timestamp: now,
          enPantalla: false,
        );
        _smsInbox.insert(0, smsItem);
        if (_smsInbox.length > 50) {
          _smsInbox.removeRange(50, _smsInbox.length);
        }
      }
    } else if (lower.startsWith('!contexto ')) {
      final ctxText = trimmed.substring(10).trim();
      if (ctxText.isNotEmpty) {
        _studioState = _studioState.copyWith(
          streamContext: ctxText,
          updatedAt: now,
        );
        _overlayServer?.emitStudioEvent('stream_context', {
          'context': ctxText,
        });
      }
    }

    notifyListeners();
  }

  /// Vuelca en lote los usuarios modificados en memoria (opcional).
  Future<void> flushDirtyUsers() async {
    if (_dirtyUserIds.isEmpty) return;
    final usersToFlush = _dirtyUserIds
        .map((id) => _users[id])
        .whereType<CommunityUser>()
        .toList();
    _dirtyUserIds.clear();
    await _repository.flushUsersBatch(usersToFlush);
  }

  // ─── Búsqueda con debounce (250ms) y filtros ──────────────────────────────

  void setSearchQuery(String query, {bool immediate = false}) {
    _searchDebounce?.cancel();
    if (immediate) {
      _searchQuery = query;
      notifyListeners();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  // ─── Ediciones manuales de CRM (1 escritura dirigida por acción) ──────────

  Future<void> saveUserFicha(CommunityUser updated) async {
    final normalizedId = CommunityUser.normalizeRawId(updated.id);
    final canonical = updated.copyWith(
      id: normalizedId,
      actualizadoEn: DateTime.now(),
    );
    _users[normalizedId] = canonical;
    _dirtyUserIds.remove(normalizedId);
    notifyListeners();
    await _repository.saveUser(canonical);
  }

  Future<void> toggleUserTtsMute(String userId) async {
    final normalized = CommunityUser.normalizeRawId(userId);
    final existing = _users[normalized];
    if (existing == null) return;
    await saveUserFicha(
      existing.copyWith(silenciadoTts: !existing.silenciadoTts),
    );
  }

  Future<void> toggleUserBan(String userId) async {
    final normalized = CommunityUser.normalizeRawId(userId);
    final existing = _users[normalized];
    if (existing == null) return;
    await saveUserFicha(
      existing.copyWith(baneado: !existing.baneado),
    );
  }

  // ─── Proyección en vivo a OBS y Buzón !sms (1 escritura por acción) ───────

  bool isMessageProjected(CommunityMessage msg) {
    final current = _studioState.featuredMessage;
    if (current == null) return false;
    return current['id'] == msg.id ||
        (current['usuario'] == msg.usuario && current['texto'] == msg.texto);
  }

  Future<void> toggleProjectedMessage(CommunityMessage? msg) async {
    final now = DateTime.now();
    if (msg == null || isMessageProjected(msg)) {
      _studioState = _studioState.copyWith(
        clearFeaturedMessage: true,
        updatedAt: now,
      );
      _overlayServer?.emitStudioEvent('featured_message', {
        'visible': false,
        'message': null,
      });
    } else {
      final payload = {
        'id': msg.id,
        'usuario': msg.usuario,
        'nombreVisible': msg.nombreVisible,
        'texto': msg.texto,
        'plataforma': msg.plataforma,
        'timestamp': msg.timestamp.toIso8601String(),
      };
      // Desactivar cualquier SMS proyectado al proyectar un mensaje normal
      for (var i = 0; i < _smsInbox.length; i++) {
        if (_smsInbox[i].enPantalla) {
          _smsInbox[i] = _smsInbox[i].copyWith(enPantalla: false);
        }
      }
      _studioState = _studioState.copyWith(
        featuredMessage: payload,
        clearFeaturedSms: true,
        updatedAt: now,
      );
      _overlayServer?.emitStudioEvent('featured_message', {
        'visible': true,
        'message': payload,
      });
    }
    notifyListeners();
    await _repository.saveStudioState(_studioState);
  }

  bool isSmsProjected(SmsInboxItem sms) {
    final current = _studioState.featuredSms;
    if (current == null) return false;
    return current['id'] == sms.id;
  }

  Future<void> toggleProjectedSms(SmsInboxItem? sms) async {
    final now = DateTime.now();
    if (sms == null || isSmsProjected(sms)) {
      for (var i = 0; i < _smsInbox.length; i++) {
        if (_smsInbox[i].enPantalla) {
          _smsInbox[i] = _smsInbox[i].copyWith(enPantalla: false);
        }
      }
      _studioState = _studioState.copyWith(
        clearFeaturedSms: true,
        updatedAt: now,
      );
      _overlayServer?.emitStudioEvent('featured_sms', {
        'visible': false,
        'sms': null,
      });
    } else {
      for (var i = 0; i < _smsInbox.length; i++) {
        final item = _smsInbox[i];
        _smsInbox[i] = item.copyWith(enPantalla: item.id == sms.id);
      }
      final payload = {
        'id': sms.id,
        'usuario': sms.usuario,
        'nombreVisible': sms.nombreVisible,
        'texto': sms.texto,
      };
      _studioState = _studioState.copyWith(
        featuredSms: payload,
        clearFeaturedMessage: true,
        updatedAt: now,
      );
      _overlayServer?.emitStudioEvent('featured_sms', {
        'visible': true,
        'sms': payload,
      });
    }
    notifyListeners();
    await _repository.saveStudioState(_studioState);
  }

  Future<void> clearActiveProjection() async {
    if (_studioState.featuredMessage != null) {
      await toggleProjectedMessage(null);
    } else if (_studioState.featuredSms != null) {
      await toggleProjectedSms(null);
    }
  }

  Future<void> deleteSms(String smsId) async {
    final wasProjected = _studioState.featuredSms?['id'] == smsId;
    _smsInbox.removeWhere((item) => item.id == smsId);
    if (wasProjected) {
      _studioState = _studioState.copyWith(
        clearFeaturedSms: true,
        updatedAt: DateTime.now(),
      );
      _overlayServer?.emitStudioEvent('featured_sms', {
        'visible': false,
        'sms': null,
      });
    }
    notifyListeners();
    await _repository.deleteSmsItem(smsId);
  }

  Future<void> clearAllSms() async {
    final ids = _smsInbox.map((e) => e.id).toList();
    _smsInbox.clear();
    if (_studioState.featuredSms != null) {
      _studioState = _studioState.copyWith(
        clearFeaturedSms: true,
        updatedAt: DateTime.now(),
      );
      _overlayServer?.emitStudioEvent('featured_sms', {
        'visible': false,
        'sms': null,
      });
    }
    notifyListeners();
    await _repository.clearSmsInbox(ids);
  }

  // ─── Contexto del directo (!contexto) y Tema del Overlay ──────────────────

  Future<void> setStreamContext(String contextText) async {
    final clean = contextText.trim();
    _studioState = _studioState.copyWith(
      streamContext: clean,
      updatedAt: DateTime.now(),
    );
    _overlayServer?.emitStudioEvent('stream_context', {
      'context': clean,
    });
    notifyListeners();
    await _repository.saveStudioState(_studioState);
  }

  Future<void> setOverlayTheme(String theme) async {
    final normalized = theme == 'light' ? 'light' : 'dark';
    _studioState = _studioState.copyWith(
      overlayTheme: normalized,
      updatedAt: DateTime.now(),
    );
    _overlayServer?.emitStudioEvent('overlay_theme', {
      'theme': normalized,
    });
    notifyListeners();
    await _repository.saveStudioState(_studioState);
  }

  // ─── Gestión de Comandos Favoritos ────────────────────────────────────────

  bool isCommandFavorite(String command) =>
      _favoriteCommands.contains(command.trim());

  void toggleFavoriteCommand(String command) {
    final clean = command.trim();
    if (clean.isEmpty) return;
    if (_favoriteCommands.contains(clean)) {
      _favoriteCommands.remove(clean);
    } else {
      _favoriteCommands.add(clean);
    }
    notifyListeners();
  }

  // ─── Control de Fuentes OBS por Escena (Argon M2-D) ───────────────────────

  void setObsSourcesSearch(String query) {
    _obsSourcesSearch = query;
    notifyListeners();
  }

  Future<void> refreshObsSources({String? sceneName}) async {
    final targetScene = (sceneName ?? _activeObsScene).trim();
    if (targetScene.isNotEmpty) {
      _activeObsScene = targetScene;
    }
    final client = _obsClient;
    if (client == null || !client.estaConectado || _activeObsScene.isEmpty) {
      _obsSources = [];
      notifyListeners();
      return;
    }
    _loadingObsSources = true;
    notifyListeners();
    try {
      _obsSources = await client.obtenerFuentesEscena(_activeObsScene);
    } finally {
      _loadingObsSources = false;
      notifyListeners();
    }
  }

  Future<void> toggleObsSourceVisibility(ObsSourceItem item) async {
    final client = _obsClient;
    final nextEnabled = !item.enabled;
    final idx = _obsSources.indexWhere((s) => s.sceneItemId == item.sceneItemId);
    if (idx != -1) {
      _obsSources[idx] = item.copyWith(enabled: nextEnabled);
      notifyListeners();
    }
    if (client != null && client.estaConectado && _activeObsScene.isNotEmpty) {
      await client.cambiarVisibilidadFuente(
        _activeObsScene,
        item.sceneItemId,
        nextEnabled,
      );
    }
  }

  Future<void> toggleObsSourceMute(ObsSourceItem item) async {
    final client = _obsClient;
    final nextMuted = !item.muted;
    final idx = _obsSources.indexWhere((s) => s.sceneItemId == item.sceneItemId);
    if (idx != -1) {
      _obsSources[idx] = item.copyWith(muted: nextMuted);
      notifyListeners();
    }
    if (client != null && client.estaConectado && item.sourceName.isNotEmpty) {
      await client.cambiarMuteInput(item.sourceName, nextMuted);
    }
  }

  // ─── Integración TTS con AppController ────────────────────────────────────

  bool isUserSilencedOrBanned(String platform, String username) {
    final user = getUser(platform, username);
    if (user == null) return false;
    return user.silenciadoTts || user.baneado;
  }

  TtsVoiceConfig? resolveVoiceConfigForUser(String platform, String username) {
    final user = getUser(platform, username);
    return user?.vozConfig;
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _flushTimer?.cancel();
    super.dispose();
  }
}
