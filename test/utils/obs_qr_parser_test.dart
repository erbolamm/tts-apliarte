import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/utils/obs_qr_parser.dart';

void main() {
  group('parsearQrObs', () {
    test('parsea host, puerto y contraseña de un QR de OBS', () {
      final datos = parsearQrObs('obsws://192.168.1.18:4455/claveDeEjemplo123');
      expect(datos, isNotNull);
      expect(datos!.host, '192.168.1.18');
      expect(datos.port, 4455);
      expect(datos.password, 'claveDeEjemplo123');
    });

    test('decodifica una contraseña con caracteres especiales codificados', () {
      final datos = parsearQrObs('obsws://192.168.1.18:4455/abc%2Fdef%3D');
      expect(datos!.password, 'abc/def=');
    });

    test('sin contraseña (autenticacion desactivada en OBS)', () {
      final datos = parsearQrObs('obsws://192.168.1.18:4455');
      expect(datos, isNotNull);
      expect(datos!.password, '');
    });

    test('sin puerto explicito usa el 4455 por defecto', () {
      final datos = parsearQrObs('obsws://192.168.1.18');
      expect(datos!.port, 4455);
    });

    test('null si el esquema no es obsws', () {
      expect(parsearQrObs('http://192.168.1.18:4455/clave'), isNull);
    });

    test('null si el texto no es una URL', () {
      expect(parsearQrObs('esto no es un QR de OBS'), isNull);
    });

    test('null si el texto esta vacio', () {
      expect(parsearQrObs(''), isNull);
    });

    test('recorta espacios sueltos alrededor del texto leido', () {
      final datos = parsearQrObs('  obsws://192.168.1.18:4455/clave  ');
      expect(datos, isNotNull);
      expect(datos!.host, '192.168.1.18');
    });
  });
}
