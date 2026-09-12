# Configuracion (resumen)

## Twitch
- `twitchUsername`: usuario.
- `twitchOauthToken`: token OAuth (con o sin `oauth:`).
- `twitchChannel`: canal.

## Traduccion
- `sourceLanguage`: `auto` o codigo (`es`, `en`, ...).
- `targetLanguage`: `auto` o codigo.
- `translationApiBaseUrl`: URL base (usa `/translate`).
- `translationApiKey`: opcional.

## TTS
- `ttsEngine`: `system` o `vibevoice`.
- System TTS: `systemLanguage`, `systemVoice`.
- VibeVoice: `vibeVoiceBaseUrl`, `vibeVoiceVoice`, `vibeVoiceCfgScale`, `vibeVoiceSteps`, `vibeVoiceSampleRate`.

## Filtros
- `deleteBangCommands`: evita leer `!comandos`.
- `allowEveryone/Mods/Vips/Subs`: permisos.
- `replaceAtUsernames`, `speakMentions`, `speakEmotes`, `dedupEmotes`.
- `userSimilarityPercent`, `userSimilarityWindowSeconds`.
- `globalSimilarityPercent`, `globalSimilarityWindowSeconds`.

## Microfono
- `useSpeechToText`: activar STT.
- `pauseTtsWhenSpeaking`: pausar TTS mientras hablas.
- `pauseSecondsAfterSpeaking`: segundos de espera.
- `poofPattern`, `banPattern`, `banConfirmationPhrase`.
- `sendDictationToChannel`.

## Websockets
- `sttCommandWebsocketUrl`.
- `chatRouterWebsocketUrl`.
- `externalCctWebsocketUrl`.

## Overlay
- `overlayBaseUrl`.
- `overlayStyle` (tipografia, colores, bordes, sombras, padding).
