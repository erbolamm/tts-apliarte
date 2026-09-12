# ESTADO — TTS ApliArte

> **Última actualización:** 2026-09-13  
> **Autor:** Javier Mateo (ApliArte / @erbolamm)  
> **Propósito de este archivo:** Que cualquier agente (humano o IA) entienda al 100 % el estado actual del proyecto sin necesidad de leer código.

---

## 1. ¿Qué es TTS ApliArte (Versión Simplificada)?

App Flutter enfocada 100% en funcionar como un asistente de voz y traducción para directos de Twitch. Su objetivo principal es recibir los mensajes del chat, traducirlos automáticamente al idioma configurado (por defecto Español) y leerlos en voz alta usando TTS.

**Nota histórica:** Anteriormente esta app era un panel de control complejo (con VDO.ninja, overlays de VPS, Portainer, etc.). Toda esa funcionalidad ha sido eliminada para mantener el proyecto limpio, ligero y centrado exclusivamente en **Chat → Traducción → TTS**.

---

## 2. Stack técnico actual

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter SDK M3 |
| Tema | Dark Mode ApliArte Kit de Marca Oficial |
| Estado | Provider + ChangeNotifier |
| Persistencia | SharedPreferences |
| TTS | flutter_tts (Nativo / Sistema) |
| Traducción | MyMemory / Lingva (con protección anti-basura) |

---

## 3. Estado de la Interfaz (Dark Theme ApliArte)

Se ha implementado una interfaz "premium" estrictamente basada en los colores de la marca ApliArte, abandonando paletas antiguas (teal/brown):

- **Fondo (Scaffold):** `#1A1A1A` (Gris carbón)
- **Tarjetas (Cards):** `#303030` (Gris clásico ApliArte) con borde fino sutil `0x22FFFFFF`
- **Cabeceras (AppBar):** `#00467B` (Azul corporativo oscuro)
- **Acentos / Botones:** `#005FA9` (Primary) y `#5ECEF5` (Activos)
- **Texto:** `#FDFDFD` (Blanco)

---

## 4. Problemas Resueltos en la última sesión

- ✅ **ApliArteDrawer canónico:** Creado menú lateral modular con navegación organizada en 3 bloques (En Directo, Configuración y OBS/Control Remoto), liberando la pantalla principal del desorden.
- ✅ **Botonera de Comandos:** Añadida tarjeta rápida persistente con comandos `/shoutout [usuario]` nativo de Twitch y `!so [streamer]` para bots de chat.
- ✅ **Kit de Marca en ThemeData:** Unificada la paleta en `ThemeData` bloqueando exactamente los tonos ApliArte (`#1A1A1A`, `#303030`, `#00467B`, `#005FA9`, `#5ECEF5`).
- ✅ **Saneamiento de TTS y Dependencias:** Eliminada la dependencia rota de `edge_tts` y gitlink vacío en `packages/`, restaurando el motor limpio y nativo con `flutter_tts`.
- ✅ **Protocolo INBOX:** Creado `PASOS-PARA-PUBLICAR.md` en la raíz y actualizado `minSdk = 35` / `targetSdk = 36` en `android/app/build.gradle.kts` (Paso 3.12-bis).
- ✅ **Calidad de código:** `flutter analyze` pasa con 0 advertencias y la suite de tests se ejecuta al 100% en verde.
- ✅ **Limpieza profunda:** Eliminado todo rastro de WebViews, VPS, VDO.ninja, control de capas (OverlayServer sigue en código base pero la UI está 100% simplificada).
- ✅ **Bug "Plase change lenguaje":** MyMemory inyectaba errores HTTP en texto como "PLEASE SELECT TWO DISTINCT LANGUAGES" cuando el idioma origen y destino coincidían. Se ha añadido un filtro en `TranslationService` para ignorar esa basura y devolver el texto original.
- ✅ **Reset Inteligente:** Añadido botón en la AppBar para volver a ajustes por defecto (Forzando el Español `es`).

---

## 5. Próximos pasos (ROADMAP) 🚀

El código base actual es estable y la UI está limpia. El proyecto local está listo para ser archivado.
Cuando decidas retomarlo, los únicos pasos pendientes para publicarlo en tienda serán:

### 🟡 PENDIENTE — Preparación para Monetización (siguiente sprint)

- **Definir modelo de negocio:**
  - Opción A: **Freemium** — app gratuita con función TTS limitada (N mensajes/min), Premium sin límite.
  - Opción B: **Ads** — banner inferior con Google AdMob (no intrusivo para streamers).
  - Opción C: **One-time purchase** en Google Play (sin suscripción, sin ads).
- **Integrar SDK de monetización elegida** (AdMob o compra in-app via `in_app_purchase`).
- **Preparar activos de tienda:** Icono, capturas del Dark Theme, descripción en ES/EN.

### 🔲 Preparación para Google Play
  - Configurar firma de lanzamiento (`keystore`).
  - Ajustar políticas de privacidad (uso de Twitch OAuth + TTS).
  - Crear iconos y capturas de pantalla del Dark Theme ApliArte.

### 🔲 Seguridad Aplicada (Completado)
  - ✅ `.env` removido del índice de Git para proteger `TWITCH_STREAM_KEY` y contraseñas.
  - ✅ `.gitignore` actualizado con reglas contra la exposición de `.env`.
  - ✅ Creado `.env.example` como plantilla para futuras instancias.
  - ℹ️ Se mantuvo el *Client ID* de Twitch en el código fuente de forma intencional: al utilizar OAuth2 Implicit Grant (basado puramente en cliente sin backend propio secreto) es completamente seguro y estándar que el ID sea público.

### 🔲 Limpieza técnica opcional

  - Mover Client ID de Twitch a `.env` / variable de build para mayor limpieza.
  - Considerar mover `PANEL_PASS` a un sistema de autenticación real si el panel vuelve a activarse.

Todo el código está empaquetado y listo para este sprint final.
