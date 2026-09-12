# Integracion VibeVoice

## 1. Servidor
- Ejecuta el servidor VibeVoice en `ws://localhost:3000`.
- Comando recomendado:
```
python -m uvicorn demo.web.app:app --reload --port 3000
```
- Para pruebas sin modelo real:
```
python -m uvicorn demo.web.fake_server:app --reload --port 3000
```

## 2. Endpoints usados
- `GET /config`: devuelve voces disponibles.
- `WS /stream`: streaming de audio PCM16.

## 3. Parametros enviados
- `text`: texto a sintetizar.
- `voice`: id de voz.
- `cfg`: cfg scale.
- `steps`: inference steps.

## 4. Reproduccion
- La app recibe PCM16 y genera un WAV streaming.
- `Sample Rate` por defecto: 24000.
