import 'package:cloud_firestore/cloud_firestore.dart';

/// Preset estructurado del catálogo de voces TTS del Estudio Remoto.
class VoicePreset {
  const VoicePreset({
    required this.id,
    required this.label,
    required this.category,
    this.emoji = '🎙️',
    this.lang = 'es-ES',
    this.pitch = 1.0,
    this.rate = 0.5,
    this.prefix,
    this.suffix,
  });

  final String id;
  final String label;
  final String category; // 'normal' | 'animal' | 'comica' | 'efecto' | 'acento'
  final String emoji;
  final String lang;
  final double pitch;
  final double rate;
  final String? prefix;
  final String? suffix;

  TtsVoiceConfig toConfig({String? customVoiceName}) {
    return TtsVoiceConfig(
      presetId: id,
      lang: lang,
      voiceName: customVoiceName,
      pitch: pitch,
      rate: rate,
      prefix: prefix,
      suffix: suffix,
    );
  }
}

/// Catálogo completo de voces portado desde `estudio.html`.
class TtsVoiceCatalog {
  static const List<VoicePreset> presets = [
    // Normal
    VoicePreset(
      id: 'normal',
      label: 'Voz estándar',
      category: 'normal',
      emoji: '🎙️',
      lang: 'es-ES',
      pitch: 1.0,
      rate: 0.5,
    ),

    // Animales
    VoicePreset(
      id: 'gato',
      label: 'Gato',
      category: 'animal',
      emoji: '🐱',
      lang: 'es-ES',
      pitch: 1.45,
      rate: 0.55,
      prefix: 'Miau, ',
      suffix: ', miau.',
    ),
    VoicePreset(
      id: 'perro',
      label: 'Perro',
      category: 'animal',
      emoji: '🐶',
      lang: 'es-ES',
      pitch: 0.85,
      rate: 0.52,
      prefix: 'Guau guau, ',
      suffix: ', guau.',
    ),
    VoicePreset(
      id: 'pato',
      label: 'Pato',
      category: 'animal',
      emoji: '🦆',
      lang: 'es-ES',
      pitch: 1.55,
      rate: 0.62,
      prefix: 'Cuac cuac, ',
      suffix: ', cuac.',
    ),
    VoicePreset(
      id: 'rana',
      label: 'Rana',
      category: 'animal',
      emoji: '🐸',
      lang: 'es-ES',
      pitch: 0.78,
      rate: 0.45,
      prefix: 'Croac, ',
      suffix: ', croac.',
    ),
    VoicePreset(
      id: 'oveja',
      label: 'Oveja',
      category: 'animal',
      emoji: '🐑',
      lang: 'es-ES',
      pitch: 1.25,
      rate: 0.46,
      prefix: 'Beee, ',
      suffix: ', beee.',
    ),
    VoicePreset(
      id: 'vaca',
      label: 'Vaca',
      category: 'animal',
      emoji: '🐮',
      lang: 'es-ES',
      pitch: 0.68,
      rate: 0.40,
      prefix: 'Muuu, ',
      suffix: ', muuu.',
    ),
    VoicePreset(
      id: 'gallo',
      label: 'Gallo',
      category: 'animal',
      emoji: '🐓',
      lang: 'es-ES',
      pitch: 1.50,
      rate: 0.60,
      prefix: 'Quiquiriquí, ',
      suffix: '.',
    ),
    VoicePreset(
      id: 'mono',
      label: 'Mono',
      category: 'animal',
      emoji: '🐵',
      lang: 'es-ES',
      pitch: 1.40,
      rate: 0.64,
      prefix: 'Uh uh ah ah, ',
      suffix: '.',
    ),
    VoicePreset(
      id: 'lobo',
      label: 'Lobo',
      category: 'animal',
      emoji: '🐺',
      lang: 'es-ES',
      pitch: 0.72,
      rate: 0.44,
      prefix: 'Auuu, ',
      suffix: '.',
    ),
    VoicePreset(
      id: 'buho',
      label: 'Búho',
      category: 'animal',
      emoji: '🦉',
      lang: 'es-ES',
      pitch: 0.90,
      rate: 0.42,
      prefix: 'Uhu uhu, ',
      suffix: '.',
    ),
    VoicePreset(
      id: 'serpiente',
      label: 'Serpiente',
      category: 'animal',
      emoji: '🐍',
      lang: 'es-ES',
      pitch: 1.15,
      rate: 0.44,
      prefix: 'Sssss, ',
      suffix: ', ssss.',
    ),
    VoicePreset(
      id: 'caballo',
      label: 'Caballo',
      category: 'animal',
      emoji: '🐴',
      lang: 'es-ES',
      pitch: 0.88,
      rate: 0.56,
      prefix: 'Hiiii, ',
      suffix: '.',
    ),

    // Cómicas
    VoicePreset(
      id: 'borracho',
      label: 'Borracho',
      category: 'comica',
      emoji: '🍺',
      lang: 'es-ES',
      pitch: 0.82,
      rate: 0.32,
      suffix: '... hip.',
    ),
    VoicePreset(
      id: 'bebe',
      label: 'Bebé',
      category: 'comica',
      emoji: '👶',
      lang: 'es-ES',
      pitch: 1.70,
      rate: 0.58,
      prefix: 'Gugú tatá, ',
    ),
    VoicePreset(
      id: 'abuelo',
      label: 'Abuelo',
      category: 'comica',
      emoji: '👴',
      lang: 'es-ES',
      pitch: 0.76,
      rate: 0.36,
    ),
    VoicePreset(
      id: 'pirata',
      label: 'Pirata',
      category: 'comica',
      emoji: '🏴‍☠️',
      lang: 'es-ES',
      pitch: 0.78,
      rate: 0.48,
      prefix: '¡Arrr marinero! ',
    ),
    VoicePreset(
      id: 'locutor',
      label: 'Locutor Épico',
      category: 'comica',
      emoji: '📻',
      lang: 'es-ES',
      pitch: 0.84,
      rate: 0.52,
    ),
    VoicePreset(
      id: 'susurro',
      label: 'Susurro',
      category: 'comica',
      emoji: '🤫',
      lang: 'es-ES',
      pitch: 1.12,
      rate: 0.38,
    ),
    VoicePreset(
      id: 'ardilla',
      label: 'Ardilla',
      category: 'comica',
      emoji: '🐿️',
      lang: 'es-ES',
      pitch: 1.85,
      rate: 0.72,
    ),
    VoicePreset(
      id: 'gigante',
      label: 'Gigante',
      category: 'comica',
      emoji: '🗿',
      lang: 'es-ES',
      pitch: 0.58,
      rate: 0.34,
    ),

    // Efectos
    VoicePreset(
      id: 'helio',
      label: 'Helio',
      category: 'efecto',
      emoji: '🎈',
      lang: 'es-ES',
      pitch: 1.80,
      rate: 0.65,
    ),
    VoicePreset(
      id: 'ogro',
      label: 'Ogro',
      category: 'efecto',
      emoji: '👹',
      lang: 'es-ES',
      pitch: 0.60,
      rate: 0.38,
    ),
    VoicePreset(
      id: 'robot',
      label: 'Robot',
      category: 'efecto',
      emoji: '🤖',
      lang: 'es-ES',
      pitch: 0.95,
      rate: 0.44,
    ),
    VoicePreset(
      id: 'walkie',
      label: 'Walkie-Talkie',
      category: 'efecto',
      emoji: '📟',
      lang: 'es-ES',
      pitch: 1.08,
      rate: 0.55,
      suffix: ' ... cambio y corto.',
    ),
    VoicePreset(
      id: 'cueva',
      label: 'Cueva',
      category: 'efecto',
      emoji: '🕳️',
      lang: 'es-ES',
      pitch: 0.74,
      rate: 0.40,
    ),
    VoicePreset(
      id: 'megafono',
      label: 'Megáfono',
      category: 'efecto',
      emoji: '📢',
      lang: 'es-ES',
      pitch: 1.18,
      rate: 0.56,
    ),
    VoicePreset(
      id: 'eco',
      label: 'Eco',
      category: 'efecto',
      emoji: '🌊',
      lang: 'es-ES',
      pitch: 0.92,
      rate: 0.45,
    ),
    VoicePreset(
      id: 'radio',
      label: 'Radio Antigua',
      category: 'efecto',
      emoji: '📡',
      lang: 'es-ES',
      pitch: 1.05,
      rate: 0.52,
    ),

    // Acentos
    VoicePreset(
      id: 'es-ES',
      label: 'Español (España)',
      category: 'acento',
      emoji: '🇪🇸',
      lang: 'es-ES',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'es-MX',
      label: 'Español (México)',
      category: 'acento',
      emoji: '🇲🇽',
      lang: 'es-MX',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'es-AR',
      label: 'Español (Argentina)',
      category: 'acento',
      emoji: '🇦🇷',
      lang: 'es-AR',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'en-US',
      label: 'Inglés (EE.UU.)',
      category: 'acento',
      emoji: '🇺🇸',
      lang: 'en-US',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'pt-BR',
      label: 'Portugués (Brasil)',
      category: 'acento',
      emoji: '🇧🇷',
      lang: 'pt-BR',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'fr-FR',
      label: 'Francés',
      category: 'acento',
      emoji: '🇫🇷',
      lang: 'fr-FR',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'it-IT',
      label: 'Italiano',
      category: 'acento',
      emoji: '🇮🇹',
      lang: 'it-IT',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'de-DE',
      label: 'Alemán',
      category: 'acento',
      emoji: '🇩🇪',
      lang: 'de-DE',
      pitch: 1.0,
      rate: 0.5,
    ),
    VoicePreset(
      id: 'ru-RU',
      label: 'Ruso',
      category: 'acento',
      emoji: '🇷🇺',
      lang: 'ru-RU',
      pitch: 1.0,
      rate: 0.5,
    ),
  ];

  static VoicePreset byId(String presetId) {
    for (final p in presets) {
      if (p.id == presetId) return p;
    }
    return presets.first;
  }

  /// Asigna un preset determinista basado en el nombre de usuario.
  static VoicePreset assignAutomaticPreset(String username) {
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return presets.first;
    var hash = 0;
    for (var i = 0; i < clean.length; i++) {
      hash = ((hash << 5) - hash) + clean.codeUnitAt(i);
      hash &= 0x7fffffff;
    }
    return presets[hash % presets.length];
  }

  /// Transforma el texto aplicando prefijos y sufijos (por ejemplo sonidos de animales)
  /// cuando el usuario tiene una configuración de voz activa.
  static String applyPresetToText(String text, TtsVoiceConfig? config) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || config == null) return trimmed;
    final preset = byId(config.presetId);
    final prefix = config.prefix ?? preset.prefix ?? '';
    final suffix = config.suffix ?? preset.suffix ?? '';
    return '$prefix$trimmed$suffix'.trim();
  }
}

/// Configuración de voz TTS personalizada de un espectador.
class TtsVoiceConfig {
  const TtsVoiceConfig({
    this.presetId = 'normal',
    this.lang = 'es-ES',
    this.voiceName,
    this.pitch = 1.0,
    this.rate = 0.5,
    this.prefix,
    this.suffix,
  });

  final String presetId;
  final String lang;
  final String? voiceName;
  final double pitch;
  final double rate;
  final String? prefix;
  final String? suffix;

  TtsVoiceConfig copyWith({
    String? presetId,
    String? lang,
    String? voiceName,
    double? pitch,
    double? rate,
    String? prefix,
    String? suffix,
  }) {
    return TtsVoiceConfig(
      presetId: presetId ?? this.presetId,
      lang: lang ?? this.lang,
      voiceName: voiceName ?? this.voiceName,
      pitch: pitch ?? this.pitch,
      rate: rate ?? this.rate,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'presetId': presetId,
      'lang': lang,
      if (voiceName != null) 'voiceName': voiceName,
      'pitch': pitch,
      'rate': rate,
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
    };
  }

  factory TtsVoiceConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TtsVoiceConfig();
    final presetId = (map['presetId'] as String?) ?? 'normal';
    final preset = TtsVoiceCatalog.byId(presetId);
    return TtsVoiceConfig(
      presetId: presetId,
      lang: (map['lang'] as String?) ?? preset.lang,
      voiceName: map['voiceName'] as String?,
      pitch: (map['pitch'] as num?)?.toDouble() ?? preset.pitch,
      rate: (map['rate'] as num?)?.toDouble() ?? preset.rate,
      prefix: (map['prefix'] as String?) ?? preset.prefix,
      suffix: (map['suffix'] as String?) ?? preset.suffix,
    );
  }
}

DateTime _parseDateTime(dynamic raw, [DateTime? fallback]) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String && raw.isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.now();
}

/// Ficha CRM de un usuario de la comunidad (compatible con `comunidad-db.js` y `firestore.rules`).
class CommunityUser {
  const CommunityUser({
    required this.id,
    required this.plataforma,
    required this.usuario,
    required this.nombreVisible,
    this.avatarUrl = '',
    this.rol = 'normal',
    this.esSuscriptor = false,
    this.vozConfig,
    this.notasContexto = '',
    this.sugerenciaSaludo = '',
    this.totalMensajes = 0,
    required this.primerMensajeEn,
    required this.ultimoMensajeEn,
    required this.actualizadoEn,
    this.ultimoTexto = '',
    this.ultimaFechaHora = '',
    this.silenciadoTts = false,
    this.baneado = false,
  });

  final String id;
  final String plataforma; // 'twitch' | 'youtube'
  final String usuario;
  final String nombreVisible;
  final String avatarUrl;
  final String rol; // 'normal' | 'vip' | 'mod' | 'admin'
  final bool esSuscriptor;
  final TtsVoiceConfig? vozConfig;
  final String notasContexto;
  final String sugerenciaSaludo;
  final int totalMensajes;
  final DateTime primerMensajeEn;
  final DateTime ultimoMensajeEn;
  final DateTime actualizadoEn;
  final String ultimoTexto;
  final String ultimaFechaHora;
  final bool silenciadoTts;
  final bool baneado;

  /// Argon Adjustment M2-B: construye ID canónico `<plataforma>_<usuario>`.
  static String buildId(String platform, String username) {
    final p = platform.toLowerCase().trim().isEmpty
        ? 'twitch'
        : platform.toLowerCase().trim();
    var u = username.toLowerCase().trim();
    while (u.startsWith('@')) {
      u = u.substring(1).trim();
    }
    return '${p}_$u';
  }

  /// Argon Adjustment M2-B: normaliza `twitch:user` o `twitch_user` a `twitch_user`.
  static String normalizeRawId(String rawId) {
    final clean = rawId.trim().toLowerCase();
    if (clean.contains(':')) {
      final parts = clean.split(':');
      final platform = parts.first.trim();
      final user = parts.sublist(1).join('_').trim();
      return buildId(platform, user);
    }
    if (clean.startsWith('twitch_') || clean.startsWith('youtube_')) {
      final idx = clean.indexOf('_');
      final platform = clean.substring(0, idx);
      final user = clean.substring(idx + 1);
      return buildId(platform, user);
    }
    return buildId('twitch', clean);
  }

  CommunityUser copyWith({
    String? id,
    String? plataforma,
    String? usuario,
    String? nombreVisible,
    String? avatarUrl,
    String? rol,
    bool? esSuscriptor,
    TtsVoiceConfig? vozConfig,
    String? notasContexto,
    String? sugerenciaSaludo,
    int? totalMensajes,
    DateTime? primerMensajeEn,
    DateTime? ultimoMensajeEn,
    DateTime? actualizadoEn,
    String? ultimoTexto,
    String? ultimaFechaHora,
    bool? silenciadoTts,
    bool? baneado,
  }) {
    return CommunityUser(
      id: id ?? this.id,
      plataforma: plataforma ?? this.plataforma,
      usuario: usuario ?? this.usuario,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rol: rol ?? this.rol,
      esSuscriptor: esSuscriptor ?? this.esSuscriptor,
      vozConfig: vozConfig ?? this.vozConfig,
      notasContexto: notasContexto ?? this.notasContexto,
      sugerenciaSaludo: sugerenciaSaludo ?? this.sugerenciaSaludo,
      totalMensajes: totalMensajes ?? this.totalMensajes,
      primerMensajeEn: primerMensajeEn ?? this.primerMensajeEn,
      ultimoMensajeEn: ultimoMensajeEn ?? this.ultimoMensajeEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      ultimoTexto: ultimoTexto ?? this.ultimoTexto,
      ultimaFechaHora: ultimaFechaHora ?? this.ultimaFechaHora,
      silenciadoTts: silenciadoTts ?? this.silenciadoTts,
      baneado: baneado ?? this.baneado,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'plataforma': plataforma,
      'usuario': usuario,
      'nombreVisible': nombreVisible,
      'avatarUrl': avatarUrl,
      'rol': rol,
      'esSuscriptor': esSuscriptor,
      if (vozConfig != null) 'vozConfig': vozConfig!.toMap(),
      'notasContexto': notasContexto,
      'sugerenciaSaludo': sugerenciaSaludo,
      'totalMensajes': totalMensajes,
      'primerMensajeEn': Timestamp.fromDate(primerMensajeEn),
      'ultimoMensajeEn': Timestamp.fromDate(ultimoMensajeEn),
      'actualizadoEn': Timestamp.fromDate(actualizadoEn),
      'ultimoTexto': ultimoTexto,
      'ultimaFechaHora': ultimaFechaHora,
      'silenciadoTts': silenciadoTts,
      'baneado': baneado,
    };
  }

  factory CommunityUser.fromMap(Map<String, dynamic> data, {String? docId}) {
    final rawPlat = (data['plataforma'] as String? ?? 'twitch').toLowerCase().trim();
    final plataforma = rawPlat == 'youtube' ? 'youtube' : 'twitch';
    final usuario = (data['usuario'] as String? ?? '').trim();
    final rawId = docId ?? (data['id'] as String?) ?? buildId(plataforma, usuario);
    final normalizedId = normalizeRawId(rawId);
    final inferredUser = usuario.isNotEmpty
        ? usuario.toLowerCase()
        : (normalizedId.contains('_')
              ? normalizedId.substring(normalizedId.indexOf('_') + 1)
              : normalizedId);

    final now = DateTime.now();
    return CommunityUser(
      id: normalizedId,
      plataforma: plataforma,
      usuario: inferredUser,
      nombreVisible: (data['nombreVisible'] as String?)?.trim().isNotEmpty == true
          ? (data['nombreVisible'] as String).trim()
          : inferredUser,
      avatarUrl: data['avatarUrl'] as String? ?? '',
      rol: data['rol'] as String? ?? 'normal',
      esSuscriptor: data['esSuscriptor'] as bool? ?? false,
      vozConfig: data['vozConfig'] is Map<String, dynamic>
          ? TtsVoiceConfig.fromMap(data['vozConfig'] as Map<String, dynamic>)
          : null,
      notasContexto: data['notasContexto'] as String? ?? '',
      sugerenciaSaludo: data['sugerenciaSaludo'] as String? ?? '',
      totalMensajes: (data['totalMensajes'] as num?)?.toInt() ?? 0,
      primerMensajeEn: _parseDateTime(data['primerMensajeEn'], now),
      ultimoMensajeEn: _parseDateTime(data['ultimoMensajeEn'], now),
      actualizadoEn: _parseDateTime(data['actualizadoEn'], now),
      ultimoTexto: data['ultimoTexto'] as String? ?? '',
      ultimaFechaHora: data['ultimaFechaHora'] as String? ?? '',
      silenciadoTts: data['silenciadoTts'] as bool? ?? false,
      baneado: data['baneado'] as bool? ?? false,
    );
  }
}

/// Mensaje individual del historial de un usuario (`usuarios/{userId}/mensajes`).
class CommunityMessage {
  const CommunityMessage({
    required this.id,
    required this.usuarioId,
    required this.plataforma,
    required this.usuario,
    required this.nombreVisible,
    required this.texto,
    this.color = '#5ECEF5',
    required this.timestamp,
    required this.fechaHora,
  });

  final String id;
  final String usuarioId;
  final String plataforma;
  final String usuario;
  final String nombreVisible;
  final String texto;
  final String color;
  final DateTime timestamp;
  final String fechaHora;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'plataforma': plataforma,
      'usuario': usuario,
      'nombreVisible': nombreVisible,
      'texto': texto,
      'color': color,
      'timestamp': Timestamp.fromDate(timestamp),
      'fechaHora': fechaHora,
    };
  }

  factory CommunityMessage.fromMap(Map<String, dynamic> data, {String? docId}) {
    final ts = _parseDateTime(data['timestamp']);
    final plat = (data['plataforma'] as String? ?? 'twitch').toLowerCase().trim();
    final user = (data['usuario'] as String? ?? '').trim();
    return CommunityMessage(
      id: docId ?? (data['id'] as String?) ?? '${ts.millisecondsSinceEpoch}',
      usuarioId: CommunityUser.normalizeRawId(
        (data['usuarioId'] as String?) ?? CommunityUser.buildId(plat, user),
      ),
      plataforma: plat,
      usuario: user,
      nombreVisible: (data['nombreVisible'] as String?) ?? user,
      texto: (data['texto'] as String?) ?? '',
      color: (data['color'] as String?) ?? '#5ECEF5',
      timestamp: ts,
      fechaHora: (data['fechaHora'] as String?) ?? _formatTime(ts),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Elemento del buzón privado `!sms`.
class SmsInboxItem {
  const SmsInboxItem({
    required this.id,
    required this.usuario,
    required this.nombreVisible,
    required this.texto,
    required this.timestamp,
    this.enPantalla = false,
  });

  final String id;
  final String usuario;
  final String nombreVisible;
  final String texto;
  final DateTime timestamp;
  final bool enPantalla;

  SmsInboxItem copyWith({
    String? id,
    String? usuario,
    String? nombreVisible,
    String? texto,
    DateTime? timestamp,
    bool? enPantalla,
  }) {
    return SmsInboxItem(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      nombreVisible: nombreVisible ?? this.nombreVisible,
      texto: texto ?? this.texto,
      timestamp: timestamp ?? this.timestamp,
      enPantalla: enPantalla ?? this.enPantalla,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'usuario': usuario,
      'nombreVisible': nombreVisible,
      'texto': texto,
      'timestamp': Timestamp.fromDate(timestamp),
      'enPantalla': enPantalla,
    };
  }

  factory SmsInboxItem.fromMap(Map<String, dynamic> data, {String? docId}) {
    final ts = _parseDateTime(data['timestamp']);
    final user = (data['usuario'] as String? ?? '').trim();
    return SmsInboxItem(
      id: docId ?? (data['id'] as String?) ?? 'sms_${ts.millisecondsSinceEpoch}',
      usuario: user,
      nombreVisible: (data['nombreVisible'] as String?) ?? user,
      texto: (data['texto'] as String?) ?? '',
      timestamp: ts,
      enPantalla: data['enPantalla'] as bool? ?? false,
    );
  }
}

/// Fuente individual de una escena de OBS Studio (`GetSceneItemList` + `GetInputMute`).
class ObsSourceItem {
  const ObsSourceItem({
    required this.sceneItemId,
    required this.sourceName,
    this.sourceType = '',
    required this.enabled,
    this.muted = false,
  });

  final int sceneItemId;
  final String sourceName;
  final String sourceType;
  final bool enabled;
  final bool muted;

  ObsSourceItem copyWith({
    int? sceneItemId,
    String? sourceName,
    String? sourceType,
    bool? enabled,
    bool? muted,
  }) {
    return ObsSourceItem(
      sceneItemId: sceneItemId ?? this.sceneItemId,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      enabled: enabled ?? this.enabled,
      muted: muted ?? this.muted,
    );
  }
}

/// Estado en tiempo real del estudio remoto (`channels/{channelId}/runtime/studio_state`).
class RemoteStudioState {
  const RemoteStudioState({
    this.featuredMessage,
    this.featuredSms,
    this.streamContext = '',
    this.overlayTheme = 'dark',
    this.activeScene = '',
    required this.updatedAt,
  });

  static const List<String> defaultContextPresets = [
    'Charlando con el chat',
    'Programando en directo',
    'Resolviendo dudas',
    'Auditando apps Flutter',
    'Pausa de 5 minutos',
    'Cierre del directo',
  ];

  final Map<String, dynamic>? featuredMessage;
  final Map<String, dynamic>? featuredSms;
  final String streamContext;
  final String overlayTheme; // 'dark' | 'light'
  final String activeScene;
  final DateTime updatedAt;

  RemoteStudioState copyWith({
    Map<String, dynamic>? featuredMessage,
    bool clearFeaturedMessage = false,
    Map<String, dynamic>? featuredSms,
    bool clearFeaturedSms = false,
    String? streamContext,
    String? overlayTheme,
    String? activeScene,
    DateTime? updatedAt,
  }) {
    return RemoteStudioState(
      featuredMessage:
          clearFeaturedMessage ? null : (featuredMessage ?? this.featuredMessage),
      featuredSms: clearFeaturedSms ? null : (featuredSms ?? this.featuredSms),
      streamContext: streamContext ?? this.streamContext,
      overlayTheme: overlayTheme ?? this.overlayTheme,
      activeScene: activeScene ?? this.activeScene,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'featuredMessage': featuredMessage,
      'featuredSms': featuredSms,
      'streamContext': streamContext,
      'overlayTheme': overlayTheme,
      'activeScene': activeScene,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory RemoteStudioState.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return RemoteStudioState(updatedAt: DateTime.now());
    }
    return RemoteStudioState(
      featuredMessage: data['featuredMessage'] is Map
          ? Map<String, dynamic>.from(data['featuredMessage'] as Map)
          : null,
      featuredSms: data['featuredSms'] is Map
          ? Map<String, dynamic>.from(data['featuredSms'] as Map)
          : null,
      streamContext: data['streamContext'] as String? ?? '',
      overlayTheme: data['overlayTheme'] as String? ?? 'dark',
      activeScene: data['activeScene'] as String? ?? '',
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }
}
