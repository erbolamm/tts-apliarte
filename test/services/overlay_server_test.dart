import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tts_apliarte/services/overlay_server.dart';

// /api/enviar es el paso 7 de la cadena directo/tts-apliarte: el panel de la
// Oficina llama aquí para enviar directo al chat en vez de copiar.

void main() {
  late OverlayServer server;

  setUp(() async {
    server = OverlayServer();
    await server.start();
  });

  tearDown(() async {
    await server.stop();
  });

  Uri enviarUri() => Uri.parse('http://127.0.0.1:${OverlayServer.port}/api/enviar');

  test('responde 503 si no hay conexion a Twitch (onEnviarMensaje sin fijar)', () async {
    final res = await http.post(enviarUri(), body: jsonEncode({'mensaje': '!so apliarte'}));
    expect(res.statusCode, 503);
    expect(jsonDecode(res.body)['ok'], false);
  });

  test('rechaza un mensaje vacio con 400', () async {
    server.onEnviarMensaje = (_) async => true;
    final res = await http.post(enviarUri(), body: jsonEncode({'mensaje': ''}));
    expect(res.statusCode, 400);
  });

  test('envia el mensaje literal al callback y responde 200 si tiene exito', () async {
    String? recibido;
    server.onEnviarMensaje = (mensaje) async {
      recibido = mensaje;
      return true;
    };
    final res = await http.post(enviarUri(), body: jsonEncode({'mensaje': '!so apliarte'}));
    expect(res.statusCode, 200);
    expect(jsonDecode(res.body)['ok'], true);
    expect(recibido, '!so apliarte');
  });

  test('responde 204 a un preflight OPTIONS', () async {
    final req = http.Request('OPTIONS', enviarUri());
    final streamed = await req.send();
    expect(streamed.statusCode, 204);
  });

  test('lleva CORS abierto para que el panel de otro origen pueda llamar', () async {
    server.onEnviarMensaje = (_) async => true;
    final res = await http.post(enviarUri(), body: jsonEncode({'mensaje': 'hola'}));
    expect(res.headers['access-control-allow-origin'], '*');
  });
}
