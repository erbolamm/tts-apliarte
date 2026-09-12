import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

/// Autenticación con Twitch mediante OAuth2 Implicit Grant en el navegador.
/// No requiere secreto de cliente.
class TwitchAuthService {
  static const _clientId = 'f5bl791rwfemk9zdp1ygmmsf2v6fnk';
  static const _redirectPort = 40475;

  /// Abre el navegador para autorizar la app.
  /// Devuelve el access token, o null si se cancela o falla.
  Future<String?> login() async {
    HttpServer? server;
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _redirectPort,
      );
    } catch (_) {
      return null;
    }

    final authUri = Uri.https('id.twitch.tv', '/oauth2/authorize', {
      'response_type': 'token',
      'client_id': _clientId,
      'redirect_uri': 'http://localhost:$_redirectPort/',
      'scope': 'chat:read chat:edit',
      'force_verify': 'false',
    });

    final launched = await launchUrl(
      authUri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      await server.close();
      return null;
    }

    final completer = Completer<String?>();

    server.listen((req) async {
      try {
        req.response.headers
          ..set('Access-Control-Allow-Origin', '*')
          ..set('Cache-Control', 'no-store');
        if (req.uri.path == '/token') {
          final token = req.uri.queryParameters['t'];
          req.response.headers.contentType = ContentType.html;
          req.response.write(_successHtml);
          await req.response.close();
          server?.close();
          if (!completer.isCompleted) completer.complete(token);
        } else {
          req.response.headers.contentType = ContentType.html;
          req.response.write(_callbackHtml);
          await req.response.close();
        }
      } catch (_) {}
    });

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        server?.close();
        return null;
      },
    );
  }

  // Página que lee el token del fragment de la URL y lo envía al servidor local.
  static final String _callbackHtml =
      '''<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><title>Conectando...</title><style>
  body { font-family: Arial, sans-serif; display: flex; align-items: center;
         justify-content: center; height: 100vh; margin: 0;
         background: #0e0e10; color: #efeff1; }
  .card { text-align: center; padding: 40px; }
  .spinner { width: 40px; height: 40px; border: 4px solid #333;
             border-top-color: #9147ff; border-radius: 50%;
             animation: spin 0.8s linear infinite; margin: 0 auto 20px; }
  @keyframes spin { to { transform: rotate(360deg); } }
</style></head>
<body><div class="card">
  <div class="spinner"></div>
  <p id="msg">Conectando con Twitch...</p>
</div><script>
var h = window.location.hash.substring(1);
var p = new URLSearchParams(h);
var t = p.get('access_token');
if (t) {
  window.location.replace('http://localhost:$_redirectPort/token?t=' + encodeURIComponent(t));
} else {
  document.getElementById('msg').textContent = 'No se encontró el token. Cierra esta ventana e inténtalo de nuevo.';
  document.querySelector('.spinner').style.display = 'none';
}
</script></body></html>''';

  static const String _successHtml = '''<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><title>Conectado</title>
<style>
  body { font-family: Arial, sans-serif; display: flex; align-items: center;
         justify-content: center; height: 100vh; margin: 0;
         background: #0e0e10; color: #efeff1; }
  .card { text-align: center; padding: 40px; }
  .check { font-size: 64px; margin-bottom: 16px; }
  h2 { color: #9147ff; margin-bottom: 8px; }
</style></head>
<body><div class="card">
  <div class="check">&#9989;</div>
  <h2>Conectado</h2>
  <p>Ya puedes cerrar esta ventana.</p>
</div></body></html>''';
}
