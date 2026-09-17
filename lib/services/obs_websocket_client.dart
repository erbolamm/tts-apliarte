import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/obs_websocket_auth.dart';

/// Una escena real de OBS, tal como la devuelve `GetSceneList`.
class ObsScene {
  const ObsScene({required this.name, required this.index});
  final String name;
  final int index;
}

/// Cliente del protocolo `obs-websocket` v5 (WebSocket propio de OBS Studio,
/// puerto 4455 por defecto — distinto de todo lo demás construido en esta
/// cadena, que son servidores propios, no OBS). Si la conexión o la
/// autenticación fallan, todos los métodos devuelven vacío/false/null sin
/// lanzar: la pantalla que lo use debe poder ocultarse sin más, no mostrar
/// un error.
class ObsWebSocketClient {
  ObsWebSocketClient({required this.host, required this.port, required this.password});

  final String host;
  final int port;
  final String password;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Completer<bool>? _identifyCompleter;
  final Map<String, Completer<Map<String, dynamic>?>> _pendientes = {};
  bool _identificado = false;

  bool get estaConectado => _identificado;

  Future<bool> conectar() async {
    if (host.isEmpty) return false;
    try {
      final canal = WebSocketChannel.connect(Uri.parse('ws://$host:$port'));
      // `connect` no lanza de forma síncrona si el host no responde: el
      // fallo llega por `ready`, que hay que esperar explícitamente dentro
      // de este try — si no, se escapa como error de Zone sin capturar
      // (comprobado con un servidor inexistente en el test de este cliente).
      await canal.ready;
      _channel = canal;
      _identifyCompleter = Completer<bool>();
      _sub = _channel!.stream.listen(
        _alRecibir,
        onError: (_) => _fallar(),
        onDone: _fallar,
        cancelOnError: true,
      );
      return await _identifyCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  void _fallar() {
    _identificado = false;
    if (_identifyCompleter != null && !_identifyCompleter!.isCompleted) {
      _identifyCompleter!.complete(false);
    }
  }

  void _alRecibir(dynamic crudo) {
    final Map<String, dynamic> mensaje;
    try {
      mensaje = jsonDecode(crudo as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final op = mensaje['op'] as int?;
    final d = mensaje['d'] as Map<String, dynamic>? ?? const {};
    switch (op) {
      case 0:
        _alRecibirHello(d);
        break;
      case 2:
        _identificado = true;
        if (_identifyCompleter != null && !_identifyCompleter!.isCompleted) {
          _identifyCompleter!.complete(true);
        }
        break;
      case 7:
        final id = d['requestId'] as String?;
        final completer = id != null ? _pendientes.remove(id) : null;
        completer?.complete(d);
        break;
    }
  }

  void _alRecibirHello(Map<String, dynamic> d) {
    final auth = d['authentication'] as Map<String, dynamic>?;
    String? respuesta;
    if (auth != null) {
      respuesta = calcularAutenticacionObs(
        password: password,
        salt: auth['salt'] as String,
        challenge: auth['challenge'] as String,
      );
    }
    _enviar({
      'op': 1,
      'd': {
        'rpcVersion': 1,
        'authentication': ?respuesta,
        'eventSubscriptions': 0,
      },
    });
  }

  void _enviar(Map<String, dynamic> mensaje) {
    _channel?.sink.add(jsonEncode(mensaje));
  }

  Future<Map<String, dynamic>?> _peticion(String tipo, [Map<String, dynamic>? datos]) async {
    if (!_identificado) return null;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<Map<String, dynamic>?>();
    _pendientes[id] = completer;
    _enviar({
      'op': 6,
      'd': {
        'requestType': tipo,
        'requestId': id,
        'requestData': ?datos,
      },
    });
    try {
      return await completer.future.timeout(const Duration(seconds: 5));
    } catch (_) {
      _pendientes.remove(id);
      return null;
    }
  }

  /// Lista de escenas reales de OBS. Vacía si no hay conexión o falla la
  /// petición — nunca lanza.
  Future<List<ObsScene>> obtenerEscenas() async {
    final res = await _peticion('GetSceneList');
    final datos = res?['responseData'] as Map<String, dynamic>?;
    final escenas = datos?['scenes'] as List<dynamic>? ?? const [];
    return escenas
        .map((e) => ObsScene(
              name: e['sceneName'] as String,
              index: e['sceneIndex'] as int,
            ))
        .toList();
  }

  /// Cambia la escena activa (programa) en OBS. false si falla, nunca lanza.
  Future<bool> cambiarEscena(String nombre) async {
    final res = await _peticion('SetCurrentProgramScene', {'sceneName': nombre});
    return res != null;
  }

  Future<void> desconectar() async {
    _identificado = false;
    await _sub?.cancel();
    await _channel?.sink.close();
  }
}
