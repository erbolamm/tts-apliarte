import 'dart:convert';

class AppSettings {
  const AppSettings({
    required this.twitchUsername,
    required this.twitchOauthToken,
    required this.twitchChannel,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.ttsEnabled,
    required this.autoTranslateEnabled,
    required this.autoTranslateToChannel,
    required this.deleteBangCommands,
    required this.allowEveryone,
    required this.allowMods,
    required this.allowVips,
    required this.allowSubs,
    required this.replaceAtUsernames,
    required this.speakMentions,
    required this.speakEmotes,
    required this.dedupEmotes,
    required this.skipTranslationIfSame,
    required this.userSimilarityPercent,
    required this.userSimilarityWindowSeconds,
    required this.globalSimilarityPercent,
    required this.globalSimilarityWindowSeconds,
    required this.pauseTtsWhenSpeaking,
    required this.pauseSecondsAfterSpeaking,
    required this.poofPattern,
    required this.banPattern,
    required this.banConfirmationPhrase,
    required this.useSpeechToText,
    required this.sendDictationToChannel,

    required this.translationApiBaseUrl,
    required this.translationApiKey,
    required this.systemLanguage,
    required this.systemVoice,
    required this.overlayBaseUrl,
    required this.scenesServerBaseUrl,
    required this.obsWebSocketHost,
    required this.obsWebSocketPort,
    required this.obsWebSocketPassword,
    required this.overlayStyle,
    required this.uiLanguage,
    required this.userVoices,
    required this.customLayers,
    required this.mentionUsers,
    required this.shoutoutUsers,
    required this.savedChannels,
    required this.savedMessages,

    required this.walkMicEnabled,
    required this.walkCamEnabled,
  });

  final String twitchUsername;
  final String twitchOauthToken;
  final String twitchChannel;
  final String sourceLanguage;
  final String targetLanguage;
  final bool ttsEnabled;
  final bool autoTranslateEnabled;
  final bool autoTranslateToChannel;
  final bool deleteBangCommands;
  final bool allowEveryone;
  final bool allowMods;
  final bool allowVips;
  final bool allowSubs;
  final bool replaceAtUsernames;
  final bool speakMentions;
  final bool speakEmotes;
  final bool dedupEmotes;
  final bool skipTranslationIfSame;
  final double userSimilarityPercent;
  final int userSimilarityWindowSeconds;
  final double globalSimilarityPercent;
  final int globalSimilarityWindowSeconds;
  final bool pauseTtsWhenSpeaking;
  final int pauseSecondsAfterSpeaking;
  final String poofPattern;
  final String banPattern;
  final String banConfirmationPhrase;
  final bool useSpeechToText;
  final bool sendDictationToChannel;

  final String translationApiBaseUrl;
  final String translationApiKey;
  final String systemLanguage;
  final String systemVoice;
  final String overlayBaseUrl;

  /// Base del servidor propio de escenas del directo (paso 4 de la cadena
  /// directo/tts-apliarte, `/api/escena`). Vacío por defecto a propósito: la
  /// app publicada no debe apuntar a ninguna infraestructura de Javier, cada
  /// usuario pone la suya (p. ej. `http://192.168.1.5:8790`).
  final String scenesServerBaseUrl;

  /// Conexión al WebSocket nativo de OBS Studio (protocolo `obs-websocket`
  /// v5, puerto 4455 por defecto en OBS) — distinto del servidor de escenas
  /// de arriba. Vacío por defecto: sin host no se intenta conectar, y la
  /// pantalla que muestre las escenas reales de OBS simplemente no aparece.
  final String obsWebSocketHost;
  final int obsWebSocketPort;
  final String obsWebSocketPassword;
  final OverlayStyle overlayStyle;
  final String uiLanguage;
  final Map<String, String> userVoices;
  final Map<String, String> customLayers;
  final List<String> mentionUsers;
  final List<String> shoutoutUsers;

  /// Canales y mensajes guardados para los comandos `/raid [canal]` y
  /// `/announce [mensaje]` de la botonera (sin dato de Javier por defecto —
  /// cada usuario guarda los suyos).
  final List<String> savedChannels;
  final List<String> savedMessages;

  /// Modo paseo (paso 3 de la cadena directo/tts-apliarte): interruptores
  /// independientes del enlace WebRTC P2P hacia directo/public/walk.html.
  /// La app no muestra preview local de la cámara — la pista sale al peer
  /// y se ve solo en el directo del PC. Por defecto apagados.
  final bool walkMicEnabled;
  final bool walkCamEnabled;

  factory AppSettings.defaults() {
    return AppSettings(
      twitchUsername: 'apliarte',
      twitchOauthToken: '',
      twitchChannel: 'apliarte',
      sourceLanguage: 'auto',
      targetLanguage: 'es',
      ttsEnabled: true,
      autoTranslateEnabled: true,
      autoTranslateToChannel: false,
      deleteBangCommands: true,
      allowEveryone: true,
      allowMods: true,
      allowVips: true,
      allowSubs: true,
      replaceAtUsernames: true,
      speakMentions: true,
      speakEmotes: true,
      dedupEmotes: true,
      skipTranslationIfSame: true,
      userSimilarityPercent: 90,
      userSimilarityWindowSeconds: 300,
      globalSimilarityPercent: 90,
      globalSimilarityWindowSeconds: 300,
      pauseTtsWhenSpeaking: false,
      pauseSecondsAfterSpeaking: 2,
      poofPattern: 'poof|proof|poop',
      banPattern:
          'band hammer|ben hammer|ban hammer|banhammer|ben hammer|jan hammer',
      banConfirmationPhrase: 'affirmative',
      useSpeechToText: false,
      sendDictationToChannel: false,

      translationApiBaseUrl: '',
      translationApiKey: '',
      systemLanguage: 'auto',
      systemVoice: 'auto',
      overlayBaseUrl: 'https://tts.bot/translator.html',
      scenesServerBaseUrl: '',
      obsWebSocketHost: '',
      obsWebSocketPort: 4455,
      obsWebSocketPassword: '',
      overlayStyle: OverlayStyle.defaults(),
      uiLanguage: 'es',
      userVoices: const {},
      customLayers: const {},
      mentionUsers: const [],
      shoutoutUsers: const [],
      savedChannels: const [],
      savedMessages: const [],

      walkMicEnabled: false,
      walkCamEnabled: false,
    );
  }

  AppSettings copyWith({
    String? twitchUsername,
    String? twitchOauthToken,
    String? twitchChannel,
    String? sourceLanguage,
    String? targetLanguage,
    bool? ttsEnabled,
    bool? autoTranslateEnabled,
    bool? autoTranslateToChannel,
    bool? deleteBangCommands,
    bool? allowEveryone,
    bool? allowMods,
    bool? allowVips,
    bool? allowSubs,
    bool? replaceAtUsernames,
    bool? speakMentions,
    bool? speakEmotes,
    bool? dedupEmotes,
    bool? skipTranslationIfSame,
    double? userSimilarityPercent,
    int? userSimilarityWindowSeconds,
    double? globalSimilarityPercent,
    int? globalSimilarityWindowSeconds,
    bool? pauseTtsWhenSpeaking,
    int? pauseSecondsAfterSpeaking,
    String? poofPattern,
    String? banPattern,
    String? banConfirmationPhrase,
    bool? useSpeechToText,
    bool? sendDictationToChannel,

    String? translationApiBaseUrl,
    String? translationApiKey,
    String? systemLanguage,
    String? systemVoice,
    String? overlayBaseUrl,
    String? scenesServerBaseUrl,
    String? obsWebSocketHost,
    int? obsWebSocketPort,
    String? obsWebSocketPassword,
    OverlayStyle? overlayStyle,
    String? uiLanguage,
    Map<String, String>? userVoices,
    Map<String, String>? customLayers,
    List<String>? mentionUsers,
    List<String>? shoutoutUsers,
    List<String>? savedChannels,
    List<String>? savedMessages,

    bool? walkMicEnabled,
    bool? walkCamEnabled,
  }) {
    return AppSettings(
      twitchUsername: twitchUsername ?? this.twitchUsername,
      twitchOauthToken: twitchOauthToken ?? this.twitchOauthToken,
      twitchChannel: twitchChannel ?? this.twitchChannel,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      autoTranslateEnabled: autoTranslateEnabled ?? this.autoTranslateEnabled,
      autoTranslateToChannel:
          autoTranslateToChannel ?? this.autoTranslateToChannel,
      deleteBangCommands: deleteBangCommands ?? this.deleteBangCommands,
      allowEveryone: allowEveryone ?? this.allowEveryone,
      allowMods: allowMods ?? this.allowMods,
      allowVips: allowVips ?? this.allowVips,
      allowSubs: allowSubs ?? this.allowSubs,
      replaceAtUsernames: replaceAtUsernames ?? this.replaceAtUsernames,
      speakMentions: speakMentions ?? this.speakMentions,
      speakEmotes: speakEmotes ?? this.speakEmotes,
      dedupEmotes: dedupEmotes ?? this.dedupEmotes,
      skipTranslationIfSame:
          skipTranslationIfSame ?? this.skipTranslationIfSame,
      userSimilarityPercent:
          userSimilarityPercent ?? this.userSimilarityPercent,
      userSimilarityWindowSeconds:
          userSimilarityWindowSeconds ?? this.userSimilarityWindowSeconds,
      globalSimilarityPercent:
          globalSimilarityPercent ?? this.globalSimilarityPercent,
      globalSimilarityWindowSeconds:
          globalSimilarityWindowSeconds ?? this.globalSimilarityWindowSeconds,
      pauseTtsWhenSpeaking: pauseTtsWhenSpeaking ?? this.pauseTtsWhenSpeaking,
      pauseSecondsAfterSpeaking:
          pauseSecondsAfterSpeaking ?? this.pauseSecondsAfterSpeaking,
      poofPattern: poofPattern ?? this.poofPattern,
      banPattern: banPattern ?? this.banPattern,
      banConfirmationPhrase:
          banConfirmationPhrase ?? this.banConfirmationPhrase,
      useSpeechToText: useSpeechToText ?? this.useSpeechToText,
      sendDictationToChannel:
          sendDictationToChannel ?? this.sendDictationToChannel,

      translationApiBaseUrl:
          translationApiBaseUrl ?? this.translationApiBaseUrl,
      translationApiKey: translationApiKey ?? this.translationApiKey,
      systemLanguage: systemLanguage ?? this.systemLanguage,
      systemVoice: systemVoice ?? this.systemVoice,
      overlayBaseUrl: overlayBaseUrl ?? this.overlayBaseUrl,
      scenesServerBaseUrl: scenesServerBaseUrl ?? this.scenesServerBaseUrl,
      obsWebSocketHost: obsWebSocketHost ?? this.obsWebSocketHost,
      obsWebSocketPort: obsWebSocketPort ?? this.obsWebSocketPort,
      obsWebSocketPassword: obsWebSocketPassword ?? this.obsWebSocketPassword,
      overlayStyle: overlayStyle ?? this.overlayStyle,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      userVoices: userVoices ?? this.userVoices,
      customLayers: customLayers ?? this.customLayers,
      mentionUsers: mentionUsers ?? this.mentionUsers,
      shoutoutUsers: shoutoutUsers ?? this.shoutoutUsers,
      savedChannels: savedChannels ?? this.savedChannels,
      savedMessages: savedMessages ?? this.savedMessages,

      walkMicEnabled: walkMicEnabled ?? this.walkMicEnabled,
      walkCamEnabled: walkCamEnabled ?? this.walkCamEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'twitchUsername': twitchUsername,
      'twitchOauthToken': twitchOauthToken,
      'twitchChannel': twitchChannel,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'ttsEnabled': ttsEnabled,
      'autoTranslateEnabled': autoTranslateEnabled,
      'autoTranslateToChannel': autoTranslateToChannel,
      'deleteBangCommands': deleteBangCommands,
      'allowEveryone': allowEveryone,
      'allowMods': allowMods,
      'allowVips': allowVips,
      'allowSubs': allowSubs,
      'replaceAtUsernames': replaceAtUsernames,
      'speakMentions': speakMentions,
      'speakEmotes': speakEmotes,
      'dedupEmotes': dedupEmotes,
      'skipTranslationIfSame': skipTranslationIfSame,
      'userSimilarityPercent': userSimilarityPercent,
      'userSimilarityWindowSeconds': userSimilarityWindowSeconds,
      'globalSimilarityPercent': globalSimilarityPercent,
      'globalSimilarityWindowSeconds': globalSimilarityWindowSeconds,
      'pauseTtsWhenSpeaking': pauseTtsWhenSpeaking,
      'pauseSecondsAfterSpeaking': pauseSecondsAfterSpeaking,
      'poofPattern': poofPattern,
      'banPattern': banPattern,
      'banConfirmationPhrase': banConfirmationPhrase,
      'useSpeechToText': useSpeechToText,
      'sendDictationToChannel': sendDictationToChannel,

      'translationApiBaseUrl': translationApiBaseUrl,
      'translationApiKey': translationApiKey,
      'systemLanguage': systemLanguage,
      'systemVoice': systemVoice,
      'overlayBaseUrl': overlayBaseUrl,
      'scenesServerBaseUrl': scenesServerBaseUrl,
      'obsWebSocketHost': obsWebSocketHost,
      'obsWebSocketPort': obsWebSocketPort,
      'obsWebSocketPassword': obsWebSocketPassword,
      'overlayStyle': overlayStyle.toJson(),
      'uiLanguage': uiLanguage,
      'userVoices': userVoices,
      'customLayers': customLayers,
      'mentionUsers': mentionUsers,
      'shoutoutUsers': shoutoutUsers,
      'savedChannels': savedChannels,
      'savedMessages': savedMessages,

      'walkMicEnabled': walkMicEnabled,
      'walkCamEnabled': walkCamEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      twitchUsername: json['twitchUsername'] as String? ?? 'apliarte',
      twitchOauthToken: json['twitchOauthToken'] as String? ?? '',
      twitchChannel: json['twitchChannel'] as String? ?? 'apliarte',
      sourceLanguage: json['sourceLanguage'] as String? ?? 'auto',
      targetLanguage: json['targetLanguage'] as String? ?? 'es',
      ttsEnabled: json['ttsEnabled'] as bool? ?? true,
      autoTranslateEnabled: json['autoTranslateEnabled'] as bool? ?? true,
      autoTranslateToChannel: json['autoTranslateToChannel'] as bool? ?? false,
      deleteBangCommands: json['deleteBangCommands'] as bool? ?? true,
      allowEveryone: json['allowEveryone'] as bool? ?? true,
      allowMods: json['allowMods'] as bool? ?? true,
      allowVips: json['allowVips'] as bool? ?? true,
      allowSubs: json['allowSubs'] as bool? ?? true,
      replaceAtUsernames: json['replaceAtUsernames'] as bool? ?? true,
      speakMentions: json['speakMentions'] as bool? ?? true,
      speakEmotes: json['speakEmotes'] as bool? ?? true,
      dedupEmotes: json['dedupEmotes'] as bool? ?? true,
      skipTranslationIfSame: json['skipTranslationIfSame'] as bool? ?? true,
      userSimilarityPercent:
          (json['userSimilarityPercent'] as num?)?.toDouble() ?? 90,
      userSimilarityWindowSeconds:
          json['userSimilarityWindowSeconds'] as int? ?? 300,
      globalSimilarityPercent:
          (json['globalSimilarityPercent'] as num?)?.toDouble() ?? 90,
      globalSimilarityWindowSeconds:
          json['globalSimilarityWindowSeconds'] as int? ?? 300,
      pauseTtsWhenSpeaking: json['pauseTtsWhenSpeaking'] as bool? ?? false,
      pauseSecondsAfterSpeaking: json['pauseSecondsAfterSpeaking'] as int? ?? 2,
      poofPattern: json['poofPattern'] as String? ?? 'poof|proof|poop',
      banPattern:
          json['banPattern'] as String? ??
          'band hammer|ben hammer|ban hammer|banhammer|ben hammer|jan hammer',
      banConfirmationPhrase:
          json['banConfirmationPhrase'] as String? ?? 'affirmative',
      useSpeechToText: json['useSpeechToText'] as bool? ?? false,
      sendDictationToChannel: json['sendDictationToChannel'] as bool? ?? false,

      translationApiBaseUrl: json['translationApiBaseUrl'] as String? ?? '',
      translationApiKey: json['translationApiKey'] as String? ?? '',
      systemLanguage: json['systemLanguage'] as String? ?? 'auto',
      systemVoice: json['systemVoice'] as String? ?? 'auto',
      overlayBaseUrl:
          json['overlayBaseUrl'] as String? ??
          'https://tts.bot/translator.html',
      scenesServerBaseUrl: json['scenesServerBaseUrl'] as String? ?? '',
      obsWebSocketHost: json['obsWebSocketHost'] as String? ?? '',
      obsWebSocketPort: json['obsWebSocketPort'] as int? ?? 4455,
      obsWebSocketPassword: json['obsWebSocketPassword'] as String? ?? '',
      overlayStyle: json['overlayStyle'] != null
          ? OverlayStyle.fromJson(json['overlayStyle'] as Map<String, dynamic>)
          : OverlayStyle.defaults(),
      uiLanguage: json['uiLanguage'] as String? ?? 'es',
      userVoices: (json['userVoices'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ?? const {},
      customLayers: (json['customLayers'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ?? const {},
      mentionUsers: (json['mentionUsers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      shoutoutUsers: (json['shoutoutUsers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      savedChannels: (json['savedChannels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      savedMessages: (json['savedMessages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],

      walkMicEnabled: json['walkMicEnabled'] as bool? ?? false,
      walkCamEnabled: json['walkCamEnabled'] as bool? ?? false,
    );
  }

  String toStorageString() => jsonEncode(toJson());

  factory AppSettings.fromStorageString(String raw) {
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  String buildOverlayUrl() {
    final params = overlayStyle.toQueryParams();
    final base = overlayBaseUrl.isEmpty
        ? 'https://tts.bot/translator.html'
        : overlayBaseUrl;
    return '$base?src=$sourceLanguage&popup=aws&channel=$twitchChannel$params';
  }
}

class OverlayStyle {
  const OverlayStyle({
    required this.fontFamily,
    required this.fontWeight,
    required this.fontSize,
    required this.fontColor,
    required this.fontColorOpacity,
    required this.webkitTextStrokeSize,
    required this.webkitTextStrokeColor,
    required this.webkitTextStrokeColorOpacity,
    required this.bubbleBackgroundColor,
    required this.bubbleBackgroundOpacity,
    required this.borderColor,
    required this.borderOpacity,
    required this.borderWidth,
    required this.borderLineStyle,
    required this.borderRadius,
    required this.hrColor,
    required this.hrOpacity,
    required this.outlineColor,
    required this.outlineOpacity,
    required this.outlineOffset,
    required this.shadowColor,
    required this.shadowOpacity,
    required this.shadowOffsetHorizontal,
    required this.shadowOffsetVertical,
    required this.shadowBlur,
    required this.padding,
  });

  final String fontFamily;
  final int fontWeight;
  final double fontSize;
  final String fontColor;
  final double fontColorOpacity;
  final double webkitTextStrokeSize;
  final String webkitTextStrokeColor;
  final double webkitTextStrokeColorOpacity;
  final String bubbleBackgroundColor;
  final double bubbleBackgroundOpacity;
  final String borderColor;
  final double borderOpacity;
  final double borderWidth;
  final String borderLineStyle;
  final double borderRadius;
  final String hrColor;
  final double hrOpacity;
  final String outlineColor;
  final double outlineOpacity;
  final double outlineOffset;
  final String shadowColor;
  final double shadowOpacity;
  final double shadowOffsetHorizontal;
  final double shadowOffsetVertical;
  final double shadowBlur;
  final double padding;

  factory OverlayStyle.defaults() {
    return const OverlayStyle(
      fontFamily: 'Arial, Helvetica',
      fontWeight: 900,
      fontSize: 30,
      fontColor: 'rgba(0, 0, 0, 1)',
      fontColorOpacity: 1,
      webkitTextStrokeSize: 0.5,
      webkitTextStrokeColor: 'rgba(0, 0, 0, 1)',
      webkitTextStrokeColorOpacity: 1,
      bubbleBackgroundColor: 'rgba(0, 0, 0, 0.5)',
      bubbleBackgroundOpacity: 0.5,
      borderColor: 'rgba(0, 0, 0, 1)',
      borderOpacity: 1,
      borderWidth: 5,
      borderLineStyle: 'solid',
      borderRadius: 25,
      hrColor: 'rgba(0, 0, 0, 1)',
      hrOpacity: 1,
      outlineColor: 'rgba(0, 0, 0, 1)',
      outlineOpacity: 1,
      outlineOffset: 1,
      shadowColor: 'rgba(0, 0, 0, 1)',
      shadowOpacity: 1,
      shadowOffsetHorizontal: 0,
      shadowOffsetVertical: 0,
      shadowBlur: 0,
      padding: 10,
    );
  }

  OverlayStyle copyWith({
    String? fontFamily,
    int? fontWeight,
    double? fontSize,
    String? fontColor,
    double? fontColorOpacity,
    double? webkitTextStrokeSize,
    String? webkitTextStrokeColor,
    double? webkitTextStrokeColorOpacity,
    String? bubbleBackgroundColor,
    double? bubbleBackgroundOpacity,
    String? borderColor,
    double? borderOpacity,
    double? borderWidth,
    String? borderLineStyle,
    double? borderRadius,
    String? hrColor,
    double? hrOpacity,
    String? outlineColor,
    double? outlineOpacity,
    double? outlineOffset,
    String? shadowColor,
    double? shadowOpacity,
    double? shadowOffsetHorizontal,
    double? shadowOffsetVertical,
    double? shadowBlur,
    double? padding,
  }) {
    return OverlayStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      fontColorOpacity: fontColorOpacity ?? this.fontColorOpacity,
      webkitTextStrokeSize: webkitTextStrokeSize ?? this.webkitTextStrokeSize,
      webkitTextStrokeColor:
          webkitTextStrokeColor ?? this.webkitTextStrokeColor,
      webkitTextStrokeColorOpacity:
          webkitTextStrokeColorOpacity ?? this.webkitTextStrokeColorOpacity,
      bubbleBackgroundColor:
          bubbleBackgroundColor ?? this.bubbleBackgroundColor,
      bubbleBackgroundOpacity:
          bubbleBackgroundOpacity ?? this.bubbleBackgroundOpacity,
      borderColor: borderColor ?? this.borderColor,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      borderWidth: borderWidth ?? this.borderWidth,
      borderLineStyle: borderLineStyle ?? this.borderLineStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      hrColor: hrColor ?? this.hrColor,
      hrOpacity: hrOpacity ?? this.hrOpacity,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineOpacity: outlineOpacity ?? this.outlineOpacity,
      outlineOffset: outlineOffset ?? this.outlineOffset,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowOffsetHorizontal:
          shadowOffsetHorizontal ?? this.shadowOffsetHorizontal,
      shadowOffsetVertical: shadowOffsetVertical ?? this.shadowOffsetVertical,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily,
      'fontWeight': fontWeight,
      'fontSize': fontSize,
      'fontColor': fontColor,
      'fontColorOpacity': fontColorOpacity,
      'webkitTextStrokeSize': webkitTextStrokeSize,
      'webkitTextStrokeColor': webkitTextStrokeColor,
      'webkitTextStrokeColorOpacity': webkitTextStrokeColorOpacity,
      'bubbleBackgroundColor': bubbleBackgroundColor,
      'bubbleBackgroundOpacity': bubbleBackgroundOpacity,
      'borderColor': borderColor,
      'borderOpacity': borderOpacity,
      'borderWidth': borderWidth,
      'borderLineStyle': borderLineStyle,
      'borderRadius': borderRadius,
      'hrColor': hrColor,
      'hrOpacity': hrOpacity,
      'outlineColor': outlineColor,
      'outlineOpacity': outlineOpacity,
      'outlineOffset': outlineOffset,
      'shadowColor': shadowColor,
      'shadowOpacity': shadowOpacity,
      'shadowOffsetHorizontal': shadowOffsetHorizontal,
      'shadowOffsetVertical': shadowOffsetVertical,
      'shadowBlur': shadowBlur,
      'padding': padding,
    };
  }

  factory OverlayStyle.fromJson(Map<String, dynamic> json) {
    return OverlayStyle(
      fontFamily: json['fontFamily'] as String? ?? 'Arial, Helvetica',
      fontWeight: json['fontWeight'] as int? ?? 900,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 30,
      fontColor: json['fontColor'] as String? ?? 'rgba(0, 0, 0, 1)',
      fontColorOpacity: (json['fontColorOpacity'] as num?)?.toDouble() ?? 1,
      webkitTextStrokeSize:
          (json['webkitTextStrokeSize'] as num?)?.toDouble() ?? 0.5,
      webkitTextStrokeColor:
          json['webkitTextStrokeColor'] as String? ?? 'rgba(0, 0, 0, 1)',
      webkitTextStrokeColorOpacity:
          (json['webkitTextStrokeColorOpacity'] as num?)?.toDouble() ?? 1,
      bubbleBackgroundColor:
          json['bubbleBackgroundColor'] as String? ?? 'rgba(0, 0, 0, 0.5)',
      bubbleBackgroundOpacity:
          (json['bubbleBackgroundOpacity'] as num?)?.toDouble() ?? 0.5,
      borderColor: json['borderColor'] as String? ?? 'rgba(0, 0, 0, 1)',
      borderOpacity: (json['borderOpacity'] as num?)?.toDouble() ?? 1,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 5,
      borderLineStyle: json['borderLineStyle'] as String? ?? 'solid',
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 25,
      hrColor: json['hrColor'] as String? ?? 'rgba(0, 0, 0, 1)',
      hrOpacity: (json['hrOpacity'] as num?)?.toDouble() ?? 1,
      outlineColor: json['outlineColor'] as String? ?? 'rgba(0, 0, 0, 1)',
      outlineOpacity: (json['outlineOpacity'] as num?)?.toDouble() ?? 1,
      outlineOffset: (json['outlineOffset'] as num?)?.toDouble() ?? 1,
      shadowColor: json['shadowColor'] as String? ?? 'rgba(0, 0, 0, 1)',
      shadowOpacity: (json['shadowOpacity'] as num?)?.toDouble() ?? 1,
      shadowOffsetHorizontal:
          (json['shadowOffsetHorizontal'] as num?)?.toDouble() ?? 0,
      shadowOffsetVertical:
          (json['shadowOffsetVertical'] as num?)?.toDouble() ?? 0,
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 0,
      padding: (json['padding'] as num?)?.toDouble() ?? 10,
    );
  }

  String toQueryParams() {
    String encode(String value) => Uri.encodeComponent(value);
    return '&font-family=${encode(fontFamily)}'
        '&font-weight=$fontWeight'
        '&font-color=${encode(fontColor)}'
        '&font-size=$fontSize'
        '&webkit-text-stroke-size=$webkitTextStrokeSize'
        '&webkit-text-stroke-color=${encode(webkitTextStrokeColor)}'
        '&bubble-background-color=${encode(bubbleBackgroundColor)}'
        '&border-color=${encode(borderColor)}'
        '&border-width=$borderWidth'
        '&border-line-style=${encode(borderLineStyle)}'
        '&border-radius=$borderRadius'
        '&hr-color=${encode(hrColor)}'
        '&outline-color=${encode(outlineColor)}'
        '&outline-offset=$outlineOffset'
        '&shadow-color=${encode(shadowColor)}'
        '&shadow-offset-horizontal=$shadowOffsetHorizontal'
        '&shadow-offset-vertical=$shadowOffsetVertical'
        '&shadow-blur=$shadowBlur'
        '&padding=$padding';
  }
}
