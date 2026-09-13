# TTS ApliArte

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Apoya%20con%20un%20café-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/C0C11TWR1K)
[![PayPal](https://img.shields.io/badge/PayPal-Donar-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/erbolamm)
[![Twitch](https://img.shields.io/badge/Twitch-apliarte-9146FF?style=for-the-badge&logo=twitch&logoColor=white)](https://twitch.tv/apliarte)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-SDK%20M3-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)

Flutter app for Twitch TTS with live translation for Spanish streamers. It connects to Twitch IRC, filters chat, translates when needed, and speaks messages with system voices or VibeVoice. It also supports speech-to-text commands and optional websocket routing.

## Features
- Twitch IRC connection (chat intake + optional send)
- Auto-translate chat with custom translation API
- Role gating (mods/vips/subs/everyone)
- Similarity filters (user + global, Levenshtein)
- Mention handling and emote dedup
- Speech-to-text commands (poof / ban)
- Websocket outputs for Node-RED or external clients
- Overlay URL builder compatible with tts.bot style parameters
- VibeVoice engine (ws://localhost:3000/stream) with streaming playback

## Quick start
1. Install Flutter 3.38+.
2. In this folder, run:

```bash
flutter pub get
flutter run -d macos
```

3. Add your Twitch credentials in the UI:
- Username
- OAuth token (the app accepts with or without the `oauth:` prefix)
- Channel

4. Set translation target (for Spanish, use `es`) and a translation API base URL.
5. Click Connect.

## VibeVoice
- Run VibeVoice server on `ws://localhost:3000`.
- Pick `TTS Engine = VibeVoice` in the UI.
- Choose voice, cfg scale, and steps.
- Use `Refresh voices` to load `/config` from the server.

## Notes
- The "Delete commands starting with !" option only suppresses TTS output. It does not delete messages in Twitch chat.
- EventSub is not implemented yet. IRC is used for fast chat intake.
- Speech recognition is provided by the platform (speech_to_text plugin). Web-only "WebKit" speech is not required.

## Research
See `docs/RESEARCH.md` for the documentation sources used.

## Autor
Javier Mateo (ApliArte) — github.com/erbolamm

## 💬 Una nota personal del autor / A personal note from the author
ℹ️ Nota: El texto siguiente es un mensaje personal del autor, escrito en varios idiomas para que pueda leerlo gente de todo el mundo. Esto no implica que el proyecto tenga soporte funcional completo en esos idiomas.

ℹ️ Note: The text below is a personal message from the author, written in several languages so people around the world can read it. This does not imply full multilingual feature support in those languages.

<details>
<summary>🇪🇸 Español</summary>
TTS ApliArte es una herramienta hecha en Flutter para streamers de habla hispana. Nacio para traducir el chat en vivo, filtrar ruido y leer mensajes con voces claras (System TTS o VibeVoice). Comparto el proyecto para que otros creadores puedan montar su propio flujo de traduccion y TTS sin depender de soluciones cerradas.
</details>

<details>
<summary>🇬🇧 English</summary>
TTS ApliArte is a Flutter tool for Spanish-speaking streamers. It was created to translate live chat, reduce noise, and speak messages with clear voices (System TTS or VibeVoice). I share it so other creators can build their own translation + TTS flow without closed platforms.
</details>

<details>
<summary>🇧🇷 Português</summary>
TTS ApliArte e uma ferramenta em Flutter para streamers hispanofalantes. Foi criada para traduzir o chat ao vivo, filtrar ruido e ler mensagens com vozes claras (System TTS ou VibeVoice). Compartilho o projeto para que outros criadores montem seu proprio fluxo de traducao e TTS sem depender de plataformas fechadas.
</details>

<details>
<summary>🇫🇷 Français</summary>
TTS ApliArte est un outil Flutter pour les streamers hispanophones. Il sert a traduire le chat en direct, filtrer le bruit et lire les messages avec des voix claires (System TTS ou VibeVoice). Je le partage pour aider d'autres createurs a construire leur propre flux de traduction et TTS sans plateformes fermees.
</details>

<details>
<summary>🇩🇪 Deutsch</summary>
TTS ApliArte ist ein Flutter-Tool fur spanischsprachige Streamer. Es ubersetzt Live-Chat, filtert Rauschen und liest Nachrichten mit klaren Stimmen (System TTS oder VibeVoice). Ich teile es, damit andere Creator ihren eigenen Ubersetzungs- und TTS-Flow ohne geschlossene Plattformen bauen konnen.
</details>

<details>
<summary>🇮🇹 Italiano</summary>
TTS ApliArte e uno strumento Flutter per streamer di lingua spagnola. Serve a tradurre la chat dal vivo, filtrare il rumore e leggere i messaggi con voci chiare (System TTS o VibeVoice). Condivido il progetto per aiutare altri creator a costruire il proprio flusso di traduzione e TTS senza piattaforme chiuse.
</details>

## 💖 Apoya el proyecto
Herramienta gratuita y open source. Si te ahorra tiempo, un cafe ayuda a mantener el desarrollo.

| Plataforma | Enlace |
|-----------|--------|
| PayPal | paypal.me/erbolamm |
| Ko-fi | ko-fi.com/C0C11TWR1K |
| Twitch Tip | streamelements.com/apliarte/tip |

🌐 [Sitio Oficial / Landing](https://erbolamm.github.io/tts-apliarte/landing.html) · 📦 [GitHub](https://github.com/erbolamm/tts-apliarte)

## Licencia
MIT — © 2026 ApliArte

## About
Herramienta Flutter para TTS y traduccion en Twitch, pensada para streamers de habla hispana.
