# Research snapshot (Twitch + Flutter)

This project uses Twitch IRC over WebSocket for chat intake and Flutter plugins for TTS/STT.

## Twitch IRC
- IRC docs: https://dev.twitch.tv/docs/irc/
- WebSocket endpoint: wss://irc-ws.chat.twitch.tv:443
- Capabilities used: twitch.tv/tags, twitch.tv/commands, twitch.tv/membership
- Auth guidance: https://dev.twitch.tv/docs/chat/authenticating/
- Product lifecycle note (non-secure WS deprecation): https://dev.twitch.tv/docs/product-lifecycle/

## EventSub (future option)
- Channel chat message subscription: https://dev.twitch.tv/docs/eventsub/eventsub-subscription-types/#channelchatmessage

## Flutter packages
- flutter_tts: https://pub.dev/packages/flutter_tts
- speech_to_text: https://pub.dev/packages/speech_to_text
- web_socket_channel: https://pub.dev/packages/web_socket_channel
- shared_preferences: https://pub.dev/packages/shared_preferences
- provider: https://pub.dev/packages/provider
- http: https://pub.dev/packages/http
- google_fonts: https://pub.dev/packages/google_fonts
- just_audio: https://pub.dev/packages/just_audio
- audio_session: https://pub.dev/packages/audio_session
