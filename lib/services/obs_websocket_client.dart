import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/community_models.dart';
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

  /// Obtiene la lista de fuentes (items) de una escena de OBS (`GetSceneItemList`)
  /// y consulta en modo best-effort el estado de mute (`GetInputMute`). Nunca lanza.
  Future<List<ObsSourceItem>> obtenerFuentesEscena(String sceneName) async {
    if (!_identificado || sceneName.trim().isEmpty) return const [];
    try {
      final res = await _peticion('GetSceneItemList', {'sceneName': sceneName});
      final datos = res?['responseData'] as Map<String, dynamic>?;
      final items = datos?['sceneItems'] as List<dynamic>? ?? const [];
      final resultado = <ObsSourceItem>[];
      for (final raw in items) {
        if (raw is! Map) continue;
        final sceneItemId = (raw['sceneItemId'] as num?)?.toInt() ?? 0;
        final sourceName = (raw['sourceName'] as String?) ?? '';
        final sourceType = (raw['inputKind'] as String?) ??
            (raw['sourceType'] as String?) ??
            '';
        final enabled = (raw['sceneItemEnabled'] as bool?) ?? true;
        var muted = false;
        if (sourceName.isNotEmpty) {
          final muteRes = await _peticion('GetInputMute', {'inputName': sourceName});
          final muteData = muteRes?['responseData'] as Map<String, dynamic>?;
          if (muteData != null && muteData['inputMuted'] is bool) {
            muted = muteData['inputMuted'] as bool;
          }
        }
        resultado.add(
          ObsSourceItem(
            sceneItemId: sceneItemId,
            sourceName: sourceName,
            sourceType: sourceType,
            enabled: enabled,
            muted: muted,
          ),
        );
      }
      return resultado;
    } catch (_) {
      return const [];
    }
  }

  /// Activa o desactiva la visibilidad de una fuente en una escena (`SetSceneItemEnabled`).
  Future<bool> cambiarVisibilidadFuente(
    String sceneName,
    int sceneItemId,
    bool enabled,
  ) async {
    if (!_identificado || sceneName.trim().isEmpty) return false;
    final res = await _peticion('SetSceneItemEnabled', {
      'sceneName': sceneName,
      'sceneItemId': sceneItemId,
      'sceneItemEnabled': enabled,
    });
    return res != null;
  }

  /// Silencia o reactiva una fuente de audio en OBS (`SetInputMute`).
  Future<bool> cambiarMuteInput(String inputName, bool muted) async {
    if (!_identificado || inputName.trim().isEmpty) return false;
    final res = await _peticion('SetInputMute', {
      'inputName': inputName,
      'inputMuted': muted,
    });
    return res != null;
  }

  Future<void> desconectar() async {
    _identificado = false;
    await _sub?.cancel();
    await _channel?.sink.close();
  }
}

