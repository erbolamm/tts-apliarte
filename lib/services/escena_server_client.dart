import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/escena_server_url.dart';

/// Cliente delgado para `/api/escena` del servidor propio de `directo/`
/// (paso 4 de la cadena directo/tts-apliarte). No trae ningún valor por
/// defecto: si `baseUrl` está vacía o no es válida, no llama a ningún sitio.
class EscenaServerClient {
  const EscenaServerClient(this.baseUrl);

  final String baseUrl;

  Future<Map<String, dynamic>?> obtenerEscenaActual() async {
    final base = normalizarBaseUrlEscenas(baseUrl);
    if (base == null) return null;
    try {
      final respuesta = await http
          .get(Uri.parse(urlApiEscena(base)))
          .timeout(const Duration(seconds: 4));
      if (respuesta.statusCode != 200) return null;
      return jsonDecode(respuesta.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> cambiarEscena(String escena) async {
    final base = normalizarBaseUrlEscenas(baseUrl);
    if (base == null) return false;
    try {
      final respuesta = await http
          .post(
            Uri.parse(urlApiEscena(base)),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'escena': escena}),
          )
          .timeout(const Duration(seconds: 4));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
