import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'html_templates.dart';

/// Servidor de overlay local.
/// OBS Browser Source → http://IP_LOCAL:7979/         (1920×1080)
/// Panel móvil         → http://IP_LOCAL:7979/control  (responsive)
/// WebSocket           → ws://IP_LOCAL:7979/ws
class OverlayServer {
  static const int port = 7979;

  HttpServer? _server;
  final List<WebSocket> _clients = [];
  bool _running = false;
  String _localIp = 'localhost';

  /// Callbacks que el AppController puede inyectar.
  Future<void> Function()? onConnect;
  Future<void> Function()? onDisconnect;

  /// Estado de visibilidad de cada capa del directo.
  /// true = visible, false = oculto
  final Map<String, bool> _scenes = {
    'streamelements': true, // StreamElements overlay
    'kofi': true, // Ko-fi donaciones
    'kofi_goal': true, // Ko-fi meta
    'kofi_animated': false, // Ko-fi animado (oculto por defecto)
    'soundalerts': true, // SoundAlerts
    'chat': true, // Burbujas TTS
  };

  Map<String, String> _customLayers = {};
  String _streamSubtitle = 'PROGRAMANDO APP';
  String _streamPoweredBy = 'DIRECTO GESTIONADO POR APLIARTETTS';

  bool get isRunning => _running;
  String get overlayUrl => 'http://$_localIp:$port/';
  String get controlUrl => 'http://$_localIp:$port/control';
  String get localIp => _localIp;
  Map<String, bool> get scenes => Map.unmodifiable(_scenes);

  void updateCustomLayers(Map<String, String> customLayers) {
    // 1. Eliminar escenas que ya no están en los nuevos settings
    final keysToRemove = <String>[];
    for (final key in _customLayers.keys) {
      if (!customLayers.containsKey(key)) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _scenes.remove(key);
      _broadcast({'type': 'scene_remove', 'scene': key});
    }

    // 2. Añadir/Actualizar las nuevas customLayers
    _customLayers = customLayers;
    for (final key in customLayers.keys) {
      if (!_scenes.containsKey(key)) {
        _scenes[key] = true;
        _broadcast({'type': 'scene', 'scene': key, 'visible': true});
      }
    }
  }

  Future<void> start() async {
    if (_running) return;
    try {
      // Detectar IP local de red (Wi-Fi/Ethernet) para acceso desde móvil
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) {
              _localIp = addr.address;
              break;
            }
          }
          if (_localIp != 'localhost') break;
        }
      } catch (_) {}

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _running = true;
      _server!.listen(_handleRequest, onError: (_) {});
    } catch (_) {
      _running = false;
    }
  }

  Future<void> stop() async {
    for (final ws in List<WebSocket>.from(_clients)) {
      await ws.close().catchError((_) {});
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _running = false;
  }

  /// Muestra u oculta una escena en todos los overlays conectados.
  void setScene(String scene, {required bool visible}) {
    _scenes[scene] = visible;
    _broadcast({'type': 'scene', 'scene': scene, 'visible': visible});
  }

  bool sceneVisible(String scene) => _scenes[scene] ?? false;

  /// Envía un mensaje de chat TTS a todos los overlays conectados.
  void pushMessage({
    required String username,
    required String original,
    required String translated,
    String? language,
  }) {
    _broadcast({
      'type': 'message',
      'user': username,
      'original': original,
      'text': translated,
      'lang': language ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Notifica a los clientes del estado de conexión Twitch.
  void pushTwitchState({required bool connected}) {
    _broadcast({'type': 'twitch_state', 'connected': connected});
  }

  void _broadcast(Map<String, dynamic> payload) {
    if (_clients.isEmpty) return;
    final data = jsonEncode(payload);
    for (final ws in List<WebSocket>.from(_clients)) {
      try {
        ws.add(data);
      } catch (_) {}
    }
  }

  Future<void> _handleRequest(HttpRequest req) async {
    try {
      req.response.headers
        ..set('Access-Control-Allow-Origin', '*')
        ..set('Access-Control-Allow-Headers', '*');

      final path = req.uri.path;

      // WebSocket para el overlay y el panel de control
      if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        _clients.add(ws);
        // Enviar estado actual de escenas al conectar
        for (final e in _scenes.entries) {
          ws.add(
            jsonEncode({'type': 'scene', 'scene': e.key, 'visible': e.value}),
          );
        }
        ws.listen(
          (_) {},
          onDone: () => _clients.remove(ws),
          onError: (_) => _clients.remove(ws),
          cancelOnError: true,
        );
        return;
      }

      // API REST para el panel móvil
      if (path == '/api/scene') {
        final id = req.uri.queryParameters['id'] ?? '';
        final vis = req.uri.queryParameters['v'] == '1';
        if (_scenes.containsKey(id)) setScene(id, visible: vis);
        req.response.headers.contentType = ContentType.json;
        req.response.write(
          jsonEncode({'ok': true, 'scene': id, 'visible': vis}),
        );
        await req.response.close();
        return;
      }

      if (path == '/api/twitch') {
        final action = req.uri.queryParameters['action'];
        if (action == 'connect') await onConnect?.call();
        if (action == 'disconnect') await onDisconnect?.call();
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'ok': true}));
        await req.response.close();
        return;
      }

      // Panel de control para móvil
      if (path == '/control') {
        req.response.headers.contentType = ContentType.html;
        req.response.write(_controlHtml);
        await req.response.close();
        return;
      }

      // Overlay 1920×1080 para OBS
      req.response.headers.contentType = ContentType.html;
      req.response.write(_overlayHtml);
      await req.response.close();
    } catch (_) {}
  }

  // ─── Panel de control responsive para móvil ──────────────────────────────
  String get _controlHtml {
    final customLayersArray = _customLayers.entries.map((e) {
      return "{ id:'${e.key}', icon:'⚙️', name:'${e.key}', sub:'Personalizado' }";
    }).join(',');

    final additionalLayers = customLayersArray.isNotEmpty ? ',\n  $customLayersArray' : '';

    return '''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<title>Control — Directo</title>
<style>
  :root {
    --bg: #0e0e10; --card: #18181b; --border: #2a2a2f;
    --purple: #9147ff; --green: #1db954; --red: #e91916;
    --text: #efeff1; --muted: #848494;
  }
  * { margin:0; padding:0; box-sizing:border-box; -webkit-tap-highlight-color:transparent; }
  body { background:var(--bg); color:var(--text); font-family:'Segoe UI',Arial,sans-serif;
         min-height:100dvh; display:flex; flex-direction:column; }

  header { padding:16px; display:flex; align-items:center; gap:12px;
           border-bottom:1px solid var(--border); }
  header .logo { font-weight:800; font-size:1.1em; color:var(--purple); }
  header .dot { width:10px; height:10px; border-radius:50%; background:var(--red);
                transition:background .4s; }
  header .dot.on { background:var(--green); }

  .btn-row { display:flex; gap:10px; padding:14px 16px; }
  .btn { flex:1; padding:13px; border:none; border-radius:10px; font-size:1em;
         font-weight:700; cursor:pointer; transition:opacity .2s; }
  .btn:active { opacity:.7; }
  .btn.start  { background:var(--green); color:#fff; }
  .btn.stop   { background:var(--red); color:#fff; }

  .url-bar { margin:0 16px 14px; padding:10px 12px;
             background:var(--card); border-radius:8px;
             font-size:.78em; color:var(--muted);
             display:flex; align-items:center; gap:8px; overflow:hidden; }
  .url-bar span { flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .url-bar button { flex-shrink:0; background:none; border:1px solid var(--border);
                    color:var(--text); border-radius:6px; padding:4px 10px;
                    font-size:.85em; cursor:pointer; }

  .layers { flex:1; overflow-y:auto; padding:0 16px; display:flex; flex-direction:column; gap:8px; }
  .row { background:var(--card); border:1px solid var(--border); border-radius:10px;
         padding:12px 14px; display:flex; align-items:center; gap:12px; }
  .row .icon { font-size:1.3em; }
  .row .name { flex:1; font-size:1em; font-weight:600; }
  .row .sub  { font-size:.75em; color:var(--muted); }
  .eye { background:none; border:none; font-size:1.5em; cursor:pointer;
         padding:4px 8px; border-radius:8px; transition:background .15s; }
  .eye:active { background:rgba(255,255,255,.1); }

  .cam-wrap { margin:16px; border-radius:14px; overflow:hidden;
              background:#000; aspect-ratio:16/9; }
  .cam-wrap iframe { width:100%; height:100%; border:none; display:block; }
</style>
</head>
<body>

<header>
  <div class="dot" id="dot"></div>
  <div class="logo">TTS ApliArte</div>
  <div style="flex:1"></div>
  <div id="status-lbl" style="font-size:.85em;color:var(--muted)">Desconectado</div>
</header>

<div class="btn-row">
  <button class="btn start" onclick="twitchAction('connect')">▶ Empezar directo</button>
  <button class="btn stop"  onclick="twitchAction('disconnect')">■ Cerrar directo</button>
</div>

<div class="url-bar">
  <span>OBS → http://$_localIp:$port/</span>
  <button onclick="navigator.clipboard&&navigator.clipboard.writeText('http://$_localIp:$port/')">Copiar</button>
</div>

<div class="layers" id="layers"></div>

<script>
var LAYERS = [
  { id:'bg',            icon:'🌐', name:'Fondo web ErBolamm',     sub:'erbolamm-hub.web.app' },
  { id:'streamelements',icon:'⭐', name:'StreamElements',          sub:'Overlay personalizado' },
  { id:'kofi',          icon:'☕', name:'Ko-fi Donaciones',        sub:'Alertas de donación' },
  { id:'kofi_animated', icon:'🎉', name:'Ko-fi Animado',           sub:'(oculto por defecto)' },
  { id:'kofi_goal',     icon:'🎯', name:'Ko-fi Meta',              sub:'Barra de objetivo' },
  { id:'soundalerts',   icon:'🔊', name:'SoundAlerts',             sub:'Alertas de sonido' },
  { id:'chat',          icon:'💬', name:'Chat TTS',                sub:'Burbujas de traducción' }$additionalLayers
];

var state = {};
LAYERS.forEach(function(l){ state[l.id] = true; });
state['kofi_animated'] = false;

function buildList() {
  var el = document.getElementById('layers');
  el.innerHTML = '';
  LAYERS.forEach(function(l) {
    var div = document.createElement('div');
    div.className = 'row';
    div.innerHTML =
      '<span class="icon">' + l.icon + '</span>' +
      '<div style="flex:1"><div class="name">' + l.name + '</div>' +
        '<div class="sub">' + l.sub + '</div></div>' +
      '<button class="eye" id="eye-' + l.id + '" onclick="toggle(\\'' + l.id + '\\')">' +
        (state[l.id] ? '👁' : '🫣') + '</button>';
    el.appendChild(div);
  });
}

function toggle(id) {
  state[id] = !state[id];
  fetch('/api/scene?id=' + id + '&v=' + (state[id]?'1':'0'));
  document.getElementById('eye-' + id).textContent = state[id] ? '👁' : '🫣';
}

function twitchAction(action) {
  fetch('/api/twitch?action=' + action);
}

// WebSocket para sincronizar estado
var ws;
function connect() {
  ws = new WebSocket('ws://' + location.host + '/ws');
  ws.onmessage = function(e) {
    try {
      var d = JSON.parse(e.data);
      if (d.type === 'scene') {
        state[d.scene] = d.visible;
        var eye = document.getElementById('eye-' + d.scene);
        if (eye) eye.textContent = d.visible ? '👁' : '🫣';
      }
      if (d.type === 'twitch_state') {
        var on = d.connected;
        document.getElementById('dot').className = 'dot' + (on?' on':'');
        document.getElementById('status-lbl').textContent = on ? 'En directo' : 'Desconectado';
      }
      }
    } catch(x){}
  };
  ws.onclose = function(){ setTimeout(connect,3000); };
}

buildList();
connect();
</script>
</body></html>''';
  }

  void updateStreamInfo(String subtitle, String poweredBy) {
    _streamSubtitle = subtitle;
    _streamPoweredBy = poweredBy;
    _broadcast({'type': 'stream_info', 'subtitle': subtitle, 'poweredBy': poweredBy});
  }

  void setStreamScene(String sceneId) {
    _broadcast({'type': 'stream_scene', 'scene': sceneId});
  }

  void setStreamTimer(int minutes) {
    _broadcast({'type': 'timer', 'minutes': minutes});
  }

  // Overlay 1920×1080 para OBS (inyecta el html maestro con los assets generados dinámicamente)
  String get _overlayHtml {
    return buildMasterOverlayHtml(
      _customLayers,
      subTitle: _streamSubtitle,
      poweredBy: _streamPoweredBy,
    );
  }


}
