import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/log_entry.dart';
import '../models/twitch_message.dart';
import '../services/overlay_server.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../services/twitch_auth_service.dart';
import '../services/twitch_irc_client.dart';
import '../utils/emote_utils.dart';
import '../utils/rate_limiter.dart';
import '../utils/similarity_filter.dart';
import '../utils/voice_pitch.dart';
import 'settings_controller.dart';

class AppController extends ChangeNotifier {
  AppController({required SettingsController settingsController})
    : _settingsController = settingsController {
    _settingsController.addListener(_onSettingsChanged);
    _init();
  }

  SettingsController _settingsController;
  AppSettings get settings => _settingsController.settings;

  final TwitchIrcClient _twitch = TwitchIrcClient();
  final TtsService _tts = TtsService();
  final SpeechService _speech = SpeechService();



  final OverlayServer _overlayServer = OverlayServer();
  bool _authLoading = false;

  final SimilarityFilter _userSimilarity = SimilarityFilter();
  final SimilarityFilter _globalSimilarity = SimilarityFilter();
  final RateLimiter _chatLimiter = RateLimiter(
    maxEvents: 18,
    interval: const Duration(seconds: 30),
  );

  final List<LogEntry> _logs = [];
  bool _connected = false;
  bool _initialized = false;
  bool _speechInitialized = false;
  Future<void> _messageQueue = Future<void>.value();

  List<VoiceOption> _voices = [];
  List<VoiceOption> get voices => _voices;

  bool get isConnected => _connected;
  bool get isAuthLoading => _authLoading;
  bool get isOverlayActive => _overlayServer.isRunning;
  String get overlayUrl => _overlayServer.overlayUrl;
  String get controlUrl => _overlayServer.controlUrl;
  String get localIp => _overlayServer.localIp;
  Map<String, bool> get layers => _overlayServer.scenes;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void toggleLayer(String id, bool visible) {
    _overlayServer.setScene(id, visible: visible);
    notifyListeners();
  }

  void setStreamScene(String sceneId) {
    _overlayServer.setStreamScene(sceneId);
    notifyListeners();
  }

  void updateStreamInfo(String subtitle, String poweredBy) {
    _overlayServer.updateStreamInfo(subtitle, poweredBy);
    notifyListeners(); // Para actualizar la UI si lo mostramos
  }

  void setStreamTimer(int minutes) {
    _overlayServer.setStreamTimer(minutes);
    notifyListeners();
  }

  Future<void> _init() async {
    await _tts.init();
    _overlayServer.onConnect = () => connect();
    _overlayServer.onDisconnect = () => disconnect();
    _overlayServer.updateCustomLayers(settings.customLayers);
    await _overlayServer.start();
    _twitch.states.listen(_handleConnectionState);
    _twitch.messages.listen(_handleChatMessage);
    await _loadVoices();
    _initialized = true;
    notifyListeners();
  }

  void attachSettings(SettingsController controller) {
    if (controller == _settingsController) {
      return;
    }
    _settingsController.removeListener(_onSettingsChanged);
    _settingsController = controller;
    _settingsController.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  Future<void> connect() async {
    if (_connected) {
      return;
    }
    if (settings.twitchOauthToken.trim().isEmpty) {  
      _addLog(
        LogLevel.warning,
        'OAuth token is empty. Twitch may reject login.',
      );
    }
    _addLog(LogLevel.info, 'Connecting to Twitch IRC...');

    await _twitch.connect(
      username: settings.twitchUsername,
      oauthToken: settings.twitchOauthToken,
      channel: settings.twitchChannel,
    );

    if (settings.useSpeechToText) {
      await startSpeech();
    }
  }

  Future<void> disconnect() async {
    await _twitch.disconnect();
    await stopSpeech();
  }

  Future<void> startSpeech() async {
    if (!_speechInitialized) {
      await _speech.init();
      _speech.results.listen(_handleSpeechResult);
      _speechInitialized = true;
    }
    final localeId = _mapLanguageToLocale(settings.systemLanguage);
    await _speech.start(localeId: localeId == 'auto' ? null : localeId);
    _addLog(LogLevel.info, 'Speech recognition started.');
  }

  Future<void> stopSpeech() async {
    await _speech.stop();
    _addLog(LogLevel.info, 'Speech recognition stopped.');
  }

  bool get isSpeechListening => _speech.isListening;

  Future<void> stopTts() async {
    await _tts.stop();
  }

  Future<void> loginWithTwitch() async {
    if (_authLoading) return;
    _authLoading = true;
    notifyListeners();
    try {
      final token = await TwitchAuthService().login();
      if (token != null && token.isNotEmpty) {
        await _settingsController.updateWith(
          (s) => s.copyWith(twitchOauthToken: token),
        );
        _addLog(LogLevel.info, 'Autenticación con Twitch completada.');
      } else {
        _addLog(LogLevel.warning, 'Autenticación cancelada o no completada.');
      }
    } catch (e) {
      _addLog(LogLevel.error, 'Error de autenticación: $e');
    } finally {
      _authLoading = false;
      notifyListeners();
    }
  }

  Future<void> speakTest(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final voice = VoiceOption.fromStorage(settings.systemVoice, _voices);
    await _tts.enqueue(
      text: trimmed,
      voice: voice?.name,
      language: voice?.locale ?? _mapLanguageToLocale(settings.systemLanguage),
    );
  }

  void _handleConnectionState(TwitchConnectionState state) {
    _connected = state.connected;
    _overlayServer.pushTwitchState(connected: state.connected);
    if (state.error != null) {
      _addLog(LogLevel.error, state.error!);
    } else if (state.connected) {
      _addLog(LogLevel.info, 'Connected.');
    } else {
      _addLog(LogLevel.warning, 'Disconnected.');
    }
    notifyListeners();
  }

  Future<void> _loadVoices() async {
    final rawVoices = await _tts.getVoices();
    final options = <VoiceOption>[];
    for (final voice in rawVoices) {
      if (voice is Map) {
        final name = voice['name'];
        final locale = voice['locale'];
        if (name is String && locale is String) {
          options.add(VoiceOption(name: name, locale: locale));
        }
      }
    }
    _voices = options;
    notifyListeners();
  }


  void _handleChatMessage(TwitchChatMessage message) {
    _messageQueue = _messageQueue.then((_) => _processChatMessage(message));
  }

  // Bots conocidos de Twitch que nunca deben leerse por TTS
  static const _knownBots = {
    'streamelements',
    'nightbot',
    'moobot',
    'wizebot',
    'fossabot',
    'pretzelrocks',
    'soundalerts',
    'botrix',
    'streamlabs',
    'streamlabsbot',
    'phantombot',
    'deepbot',
    'coebot',
    'hnlbot',
    'ohbot',
    'ankhbot',
    'streamcaptainbot',
    'kofistreambot',
    'ko_fi',
  };

  Future<void> _processChatMessage(TwitchChatMessage message) async {
    if (!settings.ttsEnabled) {
      return;
    }

    // Ignorar bots conocidos (comparación case-insensitive)
    if (_knownBots.contains(message.username.toLowerCase())) {
      return;
    }

    final originalRawText = message.message.trim();

    // -- Javier: Comando !speak -config para personalizar acento por usuario --
    if (originalRawText.startsWith('!speak -config ')) {
      final parts = originalRawText.split(' ');
      // Formato esperado: !speak -config es-MX 1
      if (parts.length >= 3) {
        final localeCode = parts[2]; // ej: "es-MX"
        final voiceIndex = parts.length >= 4 ? int.tryParse(parts[3]) ?? 1 : 1;
        
        final newVoices = Map<String, String>.from(settings.userVoices);
        newVoices[message.username] = '$localeCode:$voiceIndex';
        _settingsController.updateWith((s) => s.copyWith(userVoices: newVoices));
        
        if (settings.autoTranslateToChannel) {
           final flags = {
             'es-AR': '🇦🇷', 'es-BO': '🇧🇴', 'es-CL': '🇨🇱', 'es-CO': '🇨🇴',
             'es-CR': '🇨🇷', 'es-CU': '🇨🇺', 'es-DO': '🇩🇴', 'es-EC': '🇪🇨',
             'es-SV': '🇸🇻', 'es-GQ': '🇬🇶', 'es-GT': '🇬🇹', 'es-HN': '🇭🇳',
             'es-MX': '🇲🇽', 'es-NI': '🇳🇮', 'es-PA': '🇵🇦', 'es-PY': '🇵🇾',
             'es-PE': '🇵🇪', 'es-PR': '🇵🇷', 'es-UY': '🇺🇾', 'es-ES': '🇪🇸',
             'gl-ES': '🇪🇸', 'ca-ES': '🇪🇸'
           };
           final flag = flags[localeCode] ?? '🎙️';
           await _sendTranslationToChat('$flag Voz $localeCode (ID:$voiceIndex) configurada para @${message.username}');
        }
      }
      return; // Fin de procesamiento para el comando
    }

    if (settings.deleteBangCommands && message.message.startsWith('!')) {
      return;
    }

    if (!_isAllowedRole(message)) {
      return;
    }

    if (_userSimilarity.isSimilar(
      key: 'user-${message.username}',
      text: message.message,
      thresholdPercent: settings.userSimilarityPercent,
      window: Duration(seconds: settings.userSimilarityWindowSeconds),
    )) {
      return;
    }

    if (_globalSimilarity.isSimilar(
      key: 'global',
      text: message.message,
      thresholdPercent: settings.globalSimilarityPercent,
      window: Duration(seconds: settings.globalSimilarityWindowSeconds),
    )) {
      return;
    }

    var text = message.message;
    if (!settings.speakMentions) {
      text = text.replaceAll(RegExp(r'@\w+'), '');
    }
    if (settings.replaceAtUsernames) {
      text = text.replaceAllMapped(RegExp(r'@(\w+)'), (match) {
        final user = match.group(1) ?? '';
        return user.replaceAll('_', ' ');
      });
    }

    if (!settings.speakEmotes && message.emotes.isNotEmpty) {
      text = EmoteUtils.removeEmotesByTag(text, message.emotes);
    }

    if (settings.dedupEmotes) {
      text = EmoteUtils.dedupTokens(text);
    }

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      return;
    }

    final targetLang = _resolveTargetLang();



    if (settings.autoTranslateEnabled && targetLang != 'auto') {
      try {
        final translator = TranslationService(
          customBaseUrl: settings.translationApiBaseUrl,
          apiKey: settings.translationApiKey,
        );
        final translated = await translator.translate(
          text: text,
          source: settings.sourceLanguage,
          target: targetLang,
        );
        if (settings.skipTranslationIfSame &&
            translated.trim().toLowerCase() == text.trim().toLowerCase()) {
          text = text;
        } else {
          text = translated;
        }

        if (settings.autoTranslateToChannel) {
          await _sendTranslationToChat(translated);
        }
      } catch (error) {
        _addLog(LogLevel.error, 'Translation error: $error');
      }
    }

    _overlayServer.pushMessage(
      username: message.displayName.isNotEmpty
          ? message.displayName
          : message.username,
      original: message.message,
      translated: text,
      language: targetLang != 'auto' ? targetLang : null,
    );

    await _waitForSpeechPause();

    final voice = VoiceOption.fromStorage(settings.systemVoice, _voices);
    final voiceLanguage = voice?.locale;
    
    // Si el usuario guardó un acento con !speak, sobrescribe el idioma por defecto
    final userSpecificData = settings.userVoices[message.username]?.split(':');
    final userSpecificLocale = userSpecificData?.isNotEmpty == true ? userSpecificData![0] : null;
    final userSpecificIndex = userSpecificData != null && userSpecificData.length > 1 
        ? int.tryParse(userSpecificData[1]) ?? 1 
        : 1;
    
    final language = userSpecificLocale ?? voiceLanguage ??
        _mapLanguageToLocale(
          settings.targetLanguage != 'auto'
              ? settings.targetLanguage
              : settings.systemLanguage,
        );

    String? finalVoiceName;
    if (userSpecificLocale != null) {
      final normalizedTarget = userSpecificLocale.toLowerCase().replaceAll('_', '-');
      final matchingVoices = _voices.where((v) {
        final loc = v.locale.toLowerCase().replaceAll('_', '-');
        return loc == normalizedTarget;
      }).toList();
      
      if (matchingVoices.isNotEmpty) {
        int idx = userSpecificIndex - 1;
        if (idx < 0 || idx >= matchingVoices.length) {
          idx = 0;
        }
        finalVoiceName = matchingVoices[idx].name;
      }
    } else {
      finalVoiceName = voice?.name;
    }

    // Sin voz manual (!speak -config), cada usuario recibe un pitch propio
    // y determinista para no sonar todos con el mismo tono del sistema.
    final userPitch = userSpecificLocale == null
        ? pitchForUsername(message.username)
        : null;

    await _tts.enqueue(
      text: text,
      voice: finalVoiceName,
      language: language == 'auto' ? null : language,
      pitch: userPitch,
    );
  }

  Future<void> _sendTranslationToChat(String message) => sendChatMessage(message);

  /// Envía un mensaje arbitrario al chat de Twitch reutilizando la conexión
  /// IRC ya activa y el limitador de tasa compartido. No hace nada si no hay
  /// conexión.
  Future<void> sendChatMessage(String message) async {
    if (!_connected) {
      return;
    }
    await _chatLimiter.waitForSlot();
    await _twitch.sendMessage(
      channel: settings.twitchChannel,
      message: message,
    );
  }

  /// Botonera: manda un shoutout oficial (/shoutout usuario) al chat en directo.
  Future<void> mentionUser(String username) {
    final clean = username.trim();
    if (clean.isEmpty) {
      return Future<void>.value();
    }
    return sendChatMessage('/shoutout $clean');
  }

  /// Botonera: manda un shoutout (!so usuario) al chat en directo.
  Future<void> shoutoutUser(String username) {
    final clean = username.trim();
    if (clean.isEmpty) {
      return Future<void>.value();
    }
    return sendChatMessage('!so $clean');
  }

  Future<void> _waitForSpeechPause() async {
    if (!settings.pauseTtsWhenSpeaking) {
      return;
    }
    if (!_speech.isListening) {
      return;
    }
    while (_speech.isListening) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await Future<void>.delayed(
      Duration(seconds: settings.pauseSecondsAfterSpeaking),
    );
  }

  Future<void> _handleSpeechResult(SpeechResult result) async {
    if (!result.isFinal) {
      return;
    }

    final text = result.text.trim();
    if (text.isEmpty) {
      return;
    }

    final poofRegex = RegExp(settings.poofPattern, caseSensitive: false);
    final banRegex = RegExp(settings.banPattern, caseSensitive: false);

    if (poofRegex.hasMatch(text)) {
      await stopTts();
      _addLog(LogLevel.info, 'Poof command detected.');
      return;
    }

    if (banRegex.hasMatch(text)) {
      await stopTts();
      await _tts.enqueue(text: settings.banConfirmationPhrase);
      _addLog(LogLevel.warning, 'Ban command detected.');
      return;
    }

    if (settings.useSpeechToText && settings.ttsEnabled) {
      final voice = VoiceOption.fromStorage(settings.systemVoice, _voices);
      await _tts.enqueue(
        text: text,
        voice: voice?.name,
        language:
            voice?.locale ?? _mapLanguageToLocale(settings.systemLanguage),
      );
    }

    if (settings.sendDictationToChannel) {
      var outgoing = text;
      final targetLang = _resolveTargetLang();
      if (settings.autoTranslateEnabled && targetLang != 'auto') {
        try {
          final translator = TranslationService(
            customBaseUrl: settings.translationApiBaseUrl,
            apiKey: settings.translationApiKey,
          );
          final translated = await translator.translate(
            text: text,
            source: settings.sourceLanguage,
            target: targetLang,
          );
          if (translated.trim().toLowerCase() != text.trim().toLowerCase()) {
            outgoing = '$text | $translated';
          }
        } catch (_) {}
      }
      await _sendTranslationToChat(outgoing);
    }
  }

  bool _isAllowedRole(TwitchChatMessage message) {
    if (settings.allowEveryone) {
      return true;
    }
    if (settings.allowMods && message.isMod) {
      return true;
    }
    if (settings.allowVips && message.isVip) {
      return true;
    }
    if (settings.allowSubs && message.isSub) {
      return true;
    }
    if (message.isBroadcaster) {
      return true;
    }
    return false;
  }



  void _onSettingsChanged() {
    if (!_initialized) {
      return;
    }
    _overlayServer.updateCustomLayers(settings.customLayers);
    
    if (settings.useSpeechToText && !_speech.isListening) {
      startSpeech();
    } else if (!settings.useSpeechToText && _speech.isListening) {
      stopSpeech();
    }
    notifyListeners();
  }

  /// Resuelve el idioma objetivo para traducción.
  /// Si ambos targetLanguage y systemLanguage son 'auto', usa el locale del
  /// dispositivo para que la traducción funcione sin configuración manual.
  String _resolveTargetLang() {
    if (settings.targetLanguage != 'auto') return settings.targetLanguage;
    if (settings.systemLanguage != 'auto') return settings.systemLanguage;
    // Ambos son 'auto': detectar idioma del dispositivo.
    final locale = Platform.localeName; // e.g. 'es_ES', 'en_US'
    return locale.split(RegExp(r'[_\-]')).first; // 'es', 'en', etc.
  }

  String _mapLanguageToLocale(String language) {
    switch (language) {
      case 'es':
        return 'es-ES';
      case 'en':
        return 'en-US';
      case 'pt':
        return 'pt-PT';
      case 'pt-BR':
        return 'pt-BR';
      case 'fr':
        return 'fr-FR';
      case 'de':
        return 'de-DE';
      case 'it':
        return 'it-IT';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      case 'zh':
        return 'zh-CN';
      case 'ru':
        return 'ru-RU';
      case 'ar':
        return 'ar-SA';
      default:
        return 'auto';
    }
  }

  void _addLog(LogLevel level, String message) {
    _logs.add(
      LogEntry(timestamp: DateTime.now(), level: level, message: message),
    );
    if (_logs.length > 300) {
      _logs.removeRange(0, _logs.length - 300);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    _twitch.dispose();
    _speech.dispose();
    _tts.stop();
    _overlayServer.stop();
    super.dispose();
  }
}

class VoiceOption {
  VoiceOption({required this.name, required this.locale});

  final String name;
  final String locale;

  String get label => '$name ($locale)';

  String get storageKey => '$name|$locale';

  static VoiceOption? fromStorage(String? raw, List<VoiceOption> voices) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final voice in voices) {
      if (voice.storageKey == raw) {
        return voice;
      }
    }
    return null;
  }
}
