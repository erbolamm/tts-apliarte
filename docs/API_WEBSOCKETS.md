# API Websockets — TTS ApliArte

## 1. STT Command Websocket
- URL configurada en `STT Command Websocket`.
- Envio:
```json
{
  "type": "stt",
  "text": "texto reconocido"
}
```

## 2. Chat Router Websocket
- URL configurada en `Chat Router Websocket`.
- Envio:
```json
{
  "type": "chat",
  "user": "usuario",
  "display": "displayName",
  "text": "mensaje",
  "channel": "canal"
}
```
- Respuesta esperada (opcional):
```json
{
  "text": "mensaje reescrito"
}
```

## 3. External CCT Websocket
- URL configurada en `External CCT Websocket`.
- Envio:
```json
{
  "type": "cct",
  "text": "texto reconocido"
}
```
