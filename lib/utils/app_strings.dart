/// Todos los textos de la interfaz en Español e Inglés.
/// Español es el idioma por defecto.
class AppStrings {
  const AppStrings(this.lang);

  final String lang;
  bool get _es => lang != 'en';

  // Control del Directo
  String get liveTitle => _es ? 'Control del Directo' : 'Live Control';
  String get liveOn => _es ? 'En directo' : 'Live';
  String get liveOff => _es ? 'Desconectado' : 'Offline';
  String get startLive => _es ? 'Empezar directo' : 'Go Live';
  String get stopLive => _es ? 'Cerrar directo' : 'End Stream';
  String get mobilePanel => _es ? 'Panel móvil' : 'Mobile Panel';
  String get layersTitle => _es ? 'Capas del overlay' : 'Overlay Layers';
  String get copyOverlayUrl =>
      _es ? 'Copiar URL del overlay' : 'Copy overlay URL';
  String get openPreview => _es ? 'Abrir preview' : 'Open preview';
  String get obsGuideTitle => _es
      ? 'Cómo añadir en OBS / Streamlabs'
      : 'How to add in OBS / Streamlabs';
  String get panelVps => _es ? 'Panel VPS' : 'VPS Panel';
  String get panelVpsTooltip => _es
      ? 'Abrir Portainer (gestión de contenedores)'
      : 'Open Portainer (container manager)';
  String get loginGoogleBtn =>
      _es ? 'Abrir ErBolamm Hub (Google)' : 'Open ErBolamm Hub (Google)';
  String get loginGoogleTooltip => _es
      ? 'Abre la web en el navegador — la sesión Google queda guardada ahí'
      : 'Opens the site in your browser — Google session is saved there';
  // Servidor propio de escenas (paso 4/5 de la cadena directo/tts-apliarte)
  String get scenesServerTitle =>
      _es ? 'Servidor de escenas' : 'Scenes server';
  String get scenesServerUrlLabel =>
      _es ? 'Dirección de tu servidor' : 'Your server address';
  String get scenesServerUrlHint => 'http://192.168.1.5:8790';
  String get scenesServerHelp => _es
      ? 'Opcional. Apunta a tu propio servidor local (ver directo/) para cambiar la escena de tu directo desde esta app. Vacío por defecto: nadie se conecta al servidor de Javier sin querer.'
      : 'Optional. Point it at your own local server (see directo/) to change your stream scene from this app. Empty by default: nobody connects to Javier\'s server by accident.';

  // Conexión al WebSocket nativo de OBS (obs-websocket v5)
  String get obsWebSocketTitle => _es ? 'Conexión con OBS' : 'OBS connection';
  String get obsWebSocketHostLabel => _es ? 'IP de tu PC con OBS' : 'IP of your OBS PC';
  String get obsWebSocketHostHint => '192.168.1.18';
  String get obsWebSocketPortLabel => _es ? 'Puerto' : 'Port';
  String get obsWebSocketPasswordLabel =>
      _es ? 'Contraseña del servidor WebSocket' : 'WebSocket server password';
  String get obsWebSocketHelp => _es
      ? 'Opcional. En OBS: Herramientas → Ajustes del servidor WebSocket → marca "Habilitar servidor WebSocket" y copia aquí la IP, el puerto y la contraseña. Vacío por defecto: sin esto, la sección de escenas de OBS no aparece.'
      : 'Optional. In OBS: Tools → WebSocket Server Settings → check "Enable WebSocket server" and copy the IP, port and password here. Empty by default: without this, the OBS scenes section does not appear.';

  String get confirmStartTitle => _es ? '¿Empezar directo?' : 'Go Live?';
  String get confirmStartMsg => _es
      ? '¿Seguro que quieres empezar el directo?'
      : 'Are you sure you want to go live?';
  String get confirmStopTitle => _es ? '¿Cerrar directo?' : 'End Stream?';
  String get confirmStopMsg => _es
      ? '¿Seguro que quieres cerrar el directo?'
      : 'Are you sure you want to end the stream?';
  String get confirmYes => _es ? 'Sí, adelante' : 'Yes, go ahead';
  String get confirmCancel => _es ? 'Cancelar' : 'Cancel';

  // AppBar
  String get appTitle => 'TTS ApliArte';
  String get twitchOnline => _es ? 'Conectado' : 'Online';
  String get twitchOffline => _es ? 'Desconectado' : 'Offline';
  String get micOn => _es ? 'Mic activo' : 'Mic On';
  String get micOff => _es ? 'Mic inactivo' : 'Mic Off';

  // Conexión Twitch
  String get connectionTitle => _es ? 'Conexión Twitch' : 'Twitch Connection';
  String get usernameLabel => _es ? 'Nombre de usuario' : 'Username';
  String get oauthToken => _es ? 'Token OAuth' : 'OAuth Token';
  String get channelLabel => _es ? 'Canal' : 'Channel';
  String get connectBtn => _es ? 'Conectar' : 'Connect';
  String get disconnectBtn => _es ? 'Desconectar' : 'Disconnect';
  String get loginTwitchBtn =>
      _es ? 'Iniciar sesión en Twitch' : 'Login with Twitch';
  String get connStep1 =>
      _es ? 'Paso 1 · Inicia sesión con Twitch' : 'Step 1 · Login with Twitch';
  String get connStep2 =>
      _es ? 'Paso 2 · Conectar al chat' : 'Step 2 · Connect to chat';
  String get connectedToChannel => _es ? 'Conectado a' : 'Connected to';
  String get notConnected =>
      _es ? 'No conectado a Twitch' : 'Not connected to Twitch';
  String get sessionActive =>
      _es ? 'Sesión de Twitch activa' : 'Twitch session active';
  String get manualConfig =>
      _es ? 'Configurar manualmente' : 'Manual configuration';
  String get changeAccount => _es ? 'Cambiar cuenta' : 'Change account';
  String get connectToChat => _es ? 'Conectar al chat' : 'Connect to chat';

  // Traducción
  String get translationTitle => _es ? 'Traducción' : 'Translation';
  String get sourceLang => _es ? 'Idioma origen' : 'Source Language';
  String get destLang => _es ? 'Idioma destino' : 'Dest Language';
  String get autoTranslate =>
      _es ? 'Traducir chat automáticamente' : 'Auto translate chat';
  String get sendTranslations =>
      _es ? 'Enviar traducción al canal' : 'Send translations to channel';
  String get skipIdentical => _es
      ? 'Omitir si la traducción es igual'
      : 'Skip if translation is identical';

  // TTS y Filtros
  String get ttsFiltersTitle => _es ? 'TTS y Filtros' : 'TTS and Filters';
  String get ttsEnabled => _es ? 'TTS activado' : 'TTS Enabled';
  String get deleteBang => _es ? 'Ignorar comandos con !' : 'Ignore ! commands';
  String get allowEveryone => _es ? 'Permitir todos' : 'Allow Everyone';
  String get allowMods => _es ? 'Permitir mods' : 'Allow Mods';
  String get allowVips => _es ? 'Permitir VIPs' : 'Allow Vips';
  String get allowSubs => _es ? 'Permitir subs' : 'Allow Subs';
  String get replaceUsernames =>
      _es ? 'Reemplazar @usuarios' : 'Replace @usernames';
  String get speakMentions => _es ? 'Leer menciones @' : 'Speak @mentions';
  String get speakEmotes => _es ? 'Leer emotes' : 'Speak emotes';
  String get dedupEmotes => _es ? 'Deduplicar emotes' : 'Dedup emotes';
  String get userSimilarity =>
      _es ? 'Similitud por usuario %' : 'User similarity %';
  String get userSimilarityTime =>
      _es ? 'Tiempo similitud usuario (s)' : 'User similarity time (s)';
  String get globalSimilarity =>
      _es ? 'Similitud global %' : 'Global similarity %';
  String get globalSimilarityTime =>
      _es ? 'Tiempo similitud global (s)' : 'Global similarity time (s)';

  // Micrófono
  String get micTitle =>
      _es ? 'Micrófono y comandos de voz' : 'Microphone & voice commands';
  String get useSpeech =>
      _es ? 'Usar reconocimiento de voz' : 'Use Speech Recognition';
  String get pauseTts =>
      _es ? 'Pausar TTS al hablar' : 'Pause TTS while speaking';
  String get secondsAfterSpeech =>
      _es ? 'Segundos de espera tras hablar' : 'Seconds to wait after speech';
  String get poofPatternLabel =>
      _es ? 'Patrón de cancelación' : 'Cancel pattern';
  String get banPatternLabel => _es ? 'Patrón de ban' : 'Ban pattern';
  String get banPhraseLabel =>
      _es ? 'Frase de confirmación del ban' : 'Ban confirmation phrase';
  String get sendDictation =>
      _es ? 'Enviar dictado al canal' : 'Send dictation to channel';
  String get startMic => _es ? 'Activar mic' : 'Start Mic';
  String get stopMic => _es ? 'Desactivar mic' : 'Stop Mic';
  String get stopTts => _es ? 'Detener TTS' : 'Stop TTS';



  // Motor de voz
  String get ttsEngineTitle => _es ? 'Motor de voz' : 'Voice Engine';
  String get systemLang => _es ? 'Idioma del sistema' : 'System Language';
  String get systemVoice => _es ? 'Voz del sistema' : 'System Voice';
  String get refreshVoices => _es ? 'Actualizar voces' : 'Refresh voices';

  // Overlay
  String get overlayTitle => 'Overlay';
  String get overlayUrlCopied =>
      _es ? 'URL del overlay copiada' : 'Overlay URL copied';
  String get overlayUrlLabel =>
      _es ? 'URL base del overlay externo' : 'External Overlay Base URL';
  String get overlayStyleTitle => _es ? 'Estilo del overlay' : 'Overlay Style';
  String get fontFamilyLbl => _es ? 'Tipografía' : 'Font Family';
  String get fontSizeLbl => _es ? 'Tamaño de fuente' : 'Font Size';
  String get fontWeightLbl => _es ? 'Grosor de fuente' : 'Font Weight';
  String get fontColorLbl =>
      _es ? 'Color del texto (rgba)' : 'Font Color (rgba)';
  String get strokeSizeLbl =>
      _es ? 'Grosor del borde del texto' : 'Text Stroke Size';
  String get strokeColorLbl =>
      _es ? 'Color del borde del texto (rgba)' : 'Text Stroke Color (rgba)';
  String get bubbleBgLbl =>
      _es ? 'Fondo del bocadillo (rgba)' : 'Bubble Background (rgba)';
  String get borderColorLbl =>
      _es ? 'Color del borde (rgba)' : 'Border Color (rgba)';
  String get borderWidthLbl => _es ? 'Ancho del borde' : 'Border Width';
  String get borderRadiusLbl => _es ? 'Radio del borde' : 'Border Radius';
  String get outlineColorLbl =>
      _es ? 'Color del contorno (rgba)' : 'Outline Color (rgba)';
  String get outlineOffsetLbl =>
      _es ? 'Distancia del contorno' : 'Outline Offset';
  String get shadowColorLbl =>
      _es ? 'Color de la sombra (rgba)' : 'Shadow Color (rgba)';
  String get shadowBlurLbl => _es ? 'Desenfoque de sombra' : 'Shadow Blur';
  String get paddingLbl => _es ? 'Espaciado interior' : 'Padding';

  // Test rápido
  String get testTitle => _es ? 'Prueba rápida' : 'Quick Test';
  String get testPlaceholder =>
      _es ? 'Escribe para probar la voz' : 'Text to test TTS';
  String get speakTestBtn => _es ? 'Probar voz' : 'Speak Test';

  // Logs
  String get logsTitle => _es ? 'Registro de eventos' : 'Event Log';
  String get logsEmpty => _es ? 'Sin eventos aún.' : 'No events yet.';

  // Idioma
  String get langToggleTooltip =>
      _es ? 'Cambiar a English' : 'Cambiar a Español';
  String get langCode => _es ? 'ES' : 'EN';

  // Botonera de comandos (shoutouts /shoutout y !so)
  String get commandButtonsTitle =>
      _es ? 'Botonera de comandos' : 'Command buttons';
  String get mentionsSectionTitle =>
      _es ? 'Shoutout nativo (/shoutout)' : 'Native shoutout (/shoutout)';
  String get shoutoutsSectionTitle =>
      _es ? 'Shoutout bot (!so)' : 'Bot shoutout (!so)';
  String get mentionInputHint =>
      _es ? 'Usuario para /shoutout' : 'Username for /shoutout';
  String get shoutoutInputHint =>
      _es ? 'Streamer para el !so' : 'Streamer for !so';
  String get addBtn => _es ? 'Añadir' : 'Add';
  String get mentionsEmpty =>
      _es ? 'Aún no hay usuarios añadidos.' : 'No users added yet.';
  String get shoutoutsEmpty =>
      _es ? 'Aún no hay streamers añadidos.' : 'No streamers added yet.';
  String get notConnectedToSend =>
      _es ? 'Conéctate al chat primero.' : 'Connect to chat first.';
  String get removeTooltip => _es ? 'Quitar' : 'Remove';
  String get fixedShoutoutTooltip => _es
      ? 'Shoutout fijo de ApliArte, creador de la app — no se puede quitar'
      : "ApliArte's fixed shoutout, the app's creator — can't be removed";
}
