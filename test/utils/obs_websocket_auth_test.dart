import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/utils/obs_websocket_auth.dart';

void main() {
  group('calcularAutenticacionObs', () {
    // Valor de referencia calculado de forma independiente con Python
    // (hashlib.sha256 + base64), no derivado del propio código Dart, para
    // que el test detecte un error real en el algoritmo, no solo repita la
    // misma implementación.
    test('coincide con el valor de referencia calculado independientemente', () {
      final resultado = calcularAutenticacionObs(
        password: 'test',
        salt: 'salt123',
        challenge: 'chal456',
      );
      expect(resultado, 'Z6pZLW3yJEeqBhZ9EGZlqk9+QuP0i069rB7+8/TPsX8=');
    });

    test('una contraseña distinta da una respuesta distinta', () {
      final a = calcularAutenticacionObs(password: 'uno', salt: 's', challenge: 'c');
      final b = calcularAutenticacionObs(password: 'dos', salt: 's', challenge: 'c');
      expect(a, isNot(equals(b)));
    });

    test('es determinista: misma entrada, misma salida', () {
      final a = calcularAutenticacionObs(password: 'p', salt: 's', challenge: 'c');
      final b = calcularAutenticacionObs(password: 'p', salt: 's', challenge: 'c');
      expect(a, b);
    });
  });
}
