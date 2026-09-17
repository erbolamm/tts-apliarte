import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/services/obs_websocket_client.dart';
import 'package:tts_apliarte/utils/obs_websocket_auth.dart';

// Servidor `obs-websocket` v5 falso, mínimo, para probar el cliente real de
// principio a fin (Hello -> Identify -> Identified -> Request ->
// RequestResponse) sin depender de que haya un OBS real arrancado. La
// contraseña aquí es de mentira, solo para este test.

const _password = 'clave-de-prueba';
const _salt = 'sal-de-prueba';
const _challenge = 'desafio-de-prueba';

Future<HttpServer> _arrancarObsFalso({List<Map<String, dynamic>> escenas = const []}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    final ws = await WebSocketTransformer.upgrade(req);
    ws.add(jsonEncode({
      'op': 0,
      'd': {
        'authentication': {'challenge': _challenge, 'salt': _salt},
      },
    }));
    ws.listen((raw) {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final op = msg['op'] as int;
      final d = msg['d'] as Map<String, dynamic>;
      if (op == 1) {
        final esperado = calcularAutenticacionObs(password: _password, salt: _salt, challenge: _challenge);
        if (d['authentication'] == esperado) {
          ws.add(jsonEncode({'op': 2, 'd': {}}));
        }
        return;
      }
      if (op == 6) {
        final tipo = d['requestType'] as String;
        final id = d['requestId'];
        if (tipo == 'GetSceneList') {
          ws.add(jsonEncode({
            'op': 7,
            'd': {
              'requestId': id,
              'requestStatus': {'result': true, 'code': 100},
              'responseData': {'scenes': escenas, 'currentProgramSceneName': ''},
            },
          }));
        } else if (tipo == 'SetCurrentProgramScene') {
          ws.add(jsonEncode({
            'op': 7,
            'd': {
              'requestId': id,
              'requestStatus': {'result': true, 'code': 100},
            },
          }));
        }
      }
    });
  });
  return server;
}

void main() {
  test('se conecta, se autentica y lee la lista real de escenas', () async {
    final server = await _arrancarObsFalso(escenas: [
      {'sceneName': 'CON_CAMARA', 'sceneIndex': 0},
      {'sceneName': 'ModoEspera', 'sceneIndex': 1},
    ]);
    final cliente = ObsWebSocketClient(
      host: server.address.address,
      port: server.port,
      password: _password,
    );

    final conectado = await cliente.conectar();
    expect(conectado, true);
    expect(cliente.estaConectado, true);

    final escenas = await cliente.obtenerEscenas();
    expect(escenas.map((e) => e.name), ['CON_CAMARA', 'ModoEspera']);

    await cliente.desconectar();
    await server.close(force: true);
  });

  test('contraseña incorrecta no llega a identificarse', () async {
    final server = await _arrancarObsFalso();
    final cliente = ObsWebSocketClient(
      host: server.address.address,
      port: server.port,
      password: 'contraseña-mala',
    );

    final conectado = await cliente.conectar();
    expect(conectado, false);
    expect(cliente.estaConectado, false);

    await server.close(force: true);
  });

  test('host vacio no intenta conectar y devuelve false', () async {
    final cliente = ObsWebSocketClient(host: '', port: 4455, password: '');
    expect(await cliente.conectar(), false);
  });

  test('servidor inexistente falla sin lanzar', () async {
    final cliente = ObsWebSocketClient(host: '127.0.0.1', port: 1, password: 'x');
    expect(await cliente.conectar(), false);
  });

  test('cambiarEscena devuelve true si OBS confirma el cambio', () async {
    final server = await _arrancarObsFalso(escenas: [
      {'sceneName': 'PAUSA', 'sceneIndex': 0},
    ]);
    final cliente = ObsWebSocketClient(
      host: server.address.address,
      port: server.port,
      password: _password,
    );
    await cliente.conectar();

    final ok = await cliente.cambiarEscena('PAUSA');
    expect(ok, true);

    await cliente.desconectar();
    await server.close(force: true);
  });
}
