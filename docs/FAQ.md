# FAQ

## El token OAuth no funciona
- Verifica que el token sea de chat y no de API.
- Revisa que no tenga espacios.

## No hay audio
- Comprueba que el motor TTS este en `system` o `vibevoice`.
- Revisa volumen y salida del sistema.

## VibeVoice no responde
- Confirma servidor activo en `ws://localhost:3000`.
- Usa `Refresh voices` para validar `/config`.

## No traduce
- `Dest Language` no puede estar en `auto`.
- La API debe responder en `/translate`.
