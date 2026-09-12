# Servidor VPS (Infraestructura de streaming)

## Datos del servidor
| Dato | Valor |
|------|-------|
| Proveedor | Hostinger VPS KVM 2 (ID: 1029708) |
| IP | 72.60.187.93 |
| SO | Ubuntu 24.04 |
| RAM | 8 GB |
| CPU | 2 vCPU |
| Disco | ~96 GB (~70 GB libres) |
| Acceso | SSH como root |

## Firewall (puertos abiertos)
| Puerto | Protocolo | Origen | Servicio |
|--------|-----------|--------|----------|
| 22 | TCP | any | SSH |
| 80 | TCP | any | HTTP (redirige a HTTPS) |
| 81 | TCP | solo IP de casa | Panel admin Nginx Proxy Manager |
| 443 | TCP | any | HTTPS (Cloudflare → NPM → servicios) |
| 7979 | TCP | cerrado | No necesario (NPM lo enruta interno) |

## Contenedores Docker activos
| Contenedor | Funcion | Puerto |
|------------|---------|--------|
| npm | Nginx Proxy Manager (reverse proxy) | 80/81/443 |
| apliarte-directos | Overlay del directo (Node.js) | 7979 (interno) |
| apliarte-streamer | Chromium + FFmpeg → Twitch | - |
| apliarte-bot | Bot de IA (8 agentes) | 18791 |
| apliarte-assistant | Asistente | 8010 |
| ai-gateway | Gateway de IA | 3000 |
| postgres | Base de datos | 5432 |
| redis | Cache | 6379 |
| n8n | Automatizaciones | 5678 (interno) |
| portainer | Gestion Docker (web) | 9000 |
| dozzle | Visor de logs Docker | 8080 (interno) |
| uptime-kuma | Monitor de uptime | 3001 |
| watchtower | Actualizacion automatica de imagenes | - |
| info-apliarte | Pagina info | 8082 |

## URLs publicas
| URL | Servicio |
|-----|----------|
| https://directo.apliarte.com | Overlay del directo (a traves de NPM) |
| https://directo.apliarte.com/panel.html | Panel de control de capas |

## Acceso al panel de NPM (Nginx Proxy Manager)
El panel de administracion de NPM esta en el puerto 81, restringido a la IP de casa.

**Desde casa (IP permitida):**
```
http://72.60.187.93:81
```

**Desde cualquier sitio (SSH tunnel):**
```bash
ssh -L 81:localhost:81 root@72.60.187.93
```
Luego abre `http://localhost:81` en el navegador.

Si tu ISP te cambia la IP publica de casa, pide a Kodee (asistente de Hostinger) que actualice la regla del firewall con la nueva IP.

## Rutas importantes en el VPS
```
/home/apliarte/docker/services/tts-overlay/
├── docker-compose.yml
├── server.js                    # Servidor overlay (Node.js)
├── data/
│   └── layers.json              # Configuracion de capas (persistente)
├── streamer/
│   ├── Dockerfile               # Imagen del streamer
│   └── start-stream.sh          # Script de inicio (Chromium + FFmpeg)
```

## Como reiniciar el streamer
```bash
ssh root@72.60.187.93
cd /home/apliarte/docker/services/tts-overlay
docker compose --profile live restart streamer
```

## Como reconstruir el streamer (tras cambios)
```bash
ssh root@72.60.187.93
cd /home/apliarte/docker/services/tts-overlay
docker compose build streamer
docker compose --profile live stop streamer
docker compose --profile live rm -f streamer
docker compose --profile live up -d streamer
```

## Bugs resueltos (referencia)
- **crypto.subtle**: Web Crypto API no funciona en HTTP. Fix: `--unsafely-treat-insecure-origin-as-secure=http://overlay:7979` en Chromium
- **GPU/SwiftShader**: `--use-gl=swiftshader` obsoleto en Chromium 145+. Fix: `--use-gl=angle --use-angle=swiftshader-webgl`
- **Barra traduccion**: Fix: `--lang=es --disable-features=TranslateUI`
