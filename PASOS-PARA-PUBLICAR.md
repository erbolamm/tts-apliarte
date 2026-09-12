# 🚀 Guía de Build & Deploy — TTS ApliArte

**Versión actual**: 1.0.0+1  
**Última actualización**: 2026-09-12  
**Mantenedor**: Francisco Mateo Márquez (Javier Mateo / ApliArte)  

---

> ⚙️ **Modo agente**: Esta guía está diseñada para ser ejecutada por un agente de IA
> de principio a fin **sin confirmaciones intermedias**, salvo puntos explícitamente marcados.

---

## 1️⃣ Preparación General (Obligatorio)

```bash
# Limpieza y resolución de dependencias
flutter clean && flutter pub get

# Verificación estricta de calidad
flutter analyze
flutter test
```

---

## 2️⃣ Android (Google Play)

### A. Requisitos previos de firma y SDK
1. Verificar que `android/app/build.gradle.kts` tenga `minSdk = 35` (regla obligatoria de ecosistema).
2. Asegurar que exista la carpeta `key/` con `upload-keystore.jks`, `upload_certificate.pem` y `leeme.txt` (nunca commitear contraseñas).
3. Asegurar que `android/key.properties` exista y esté configurado.

### B. Compilación Release

```bash
flutter build appbundle --release
```

✅ **Output**: `build/app/outputs/bundle/release/app-release.aab`

Verificar huella SHA-1 de subida:
```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA1
```

---

## 3️⃣ iOS (App Store Connect)

### A. Compilación y Pods

```bash
cd ios && pod install && cd ..
flutter build ios --release
```

### B. Xcode: Archive y Distribución (⚠️ PUNTO DE PARADA MANUAL)

**El agente se DETIENE aquí y espera instrucciones del usuario.**

1. Abrir el workspace en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Seleccionar como destino **Any iOS Device (arm64)**.
3. Menú **Product → Archive** y esperar a que finalice.
4. En la ventana **Organizer**, hacer clic en **Distribute App**.

---

## 4️⃣ macOS / Web (Distribución secundaria)

### Web (Firebase Hosting / Demo)
```bash
flutter build web --release --no-tree-shake-icons
```
✅ **Output**: `build/web/`

---

## 📋 Referencia de Versiones

| Archivo | Constante / Campo | Valor actual |
|---------|-------------------|--------------|
| `pubspec.yaml` | `version` | `1.0.0+1` |

> Al subir una nueva versión, actualizar `pubspec.yaml` y este documento.

---

## ⚠️ Notas Técnicas

- [ ] **Permisos de Audio/Micro**: Permisos gestionados al arranque con `permission_handler` para flujo de micrófono y TTS.
- [ ] **Firma Android**: NUNCA sobrescribir el keystore de subida. Dos copias seguras (una fuera de iCloud).
- [ ] **Sin SMS Auth**: Regla canónica del ecosistema (evitar costes imprevistos).
- [ ] **Filtro de traducción**: `TranslationService` cuenta con saneamiento de respuestas para evitar inyección de mensajes de error de la API (MyMemory).
