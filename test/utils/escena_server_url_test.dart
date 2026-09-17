import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/utils/escena_server_url.dart';

void main() {
  group('normalizarBaseUrlEscenas', () {
    test('vacio devuelve null: sin infraestructura de Javier por defecto', () {
      expect(normalizarBaseUrlEscenas(''), isNull);
      expect(normalizarBaseUrlEscenas('   '), isNull);
    });

    test('acepta una URL http local valida', () {
      expect(normalizarBaseUrlEscenas('http://192.168.1.5:8790'), 'http://192.168.1.5:8790');
    });

    test('acepta una URL https valida', () {
      expect(normalizarBaseUrlEscenas('https://mi-servidor.example.com'), 'https://mi-servidor.example.com');
    });

    test('quita la barra final', () {
      expect(normalizarBaseUrlEscenas('http://127.0.0.1:8790/'), 'http://127.0.0.1:8790');
    });

    test('recorta espacios sueltos', () {
      expect(normalizarBaseUrlEscenas('  http://127.0.0.1:8790  '), 'http://127.0.0.1:8790');
    });

    test('rechaza un esquema que no sea http/https', () {
      expect(normalizarBaseUrlEscenas('ftp://127.0.0.1:8790'), isNull);
    });

    test('rechaza texto que no es una URL', () {
      expect(normalizarBaseUrlEscenas('no es una url'), isNull);
    });
  });

  group('urlApiEscena', () {
    test('añade /api/escena a la base ya normalizada', () {
      expect(urlApiEscena('http://127.0.0.1:8790'), 'http://127.0.0.1:8790/api/escena');
    });
  });
}
