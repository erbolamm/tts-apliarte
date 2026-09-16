import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/utils/voice_pitch.dart';

void main() {
  group('pitchForUsername', () {
    test('es determinista: el mismo username siempre da el mismo pitch', () {
      final first = pitchForUsername('apliarte');
      final second = pitchForUsername('apliarte');
      expect(first, equals(second));
    });

    test('el pitch cae siempre dentro del rango 0.8-1.3', () {
      const usernames = [
        'apliarte',
        'javier',
        'streamelements_fan',
        'x',
        'ZZZ',
        '12345',
        'un_nombre_muy_largo_de_usuario_de_twitch',
        'nandu',
        'a',
        'b',
        'c',
      ];
      for (final username in usernames) {
        final pitch = pitchForUsername(username);
        expect(pitch, greaterThanOrEqualTo(0.8));
        expect(pitch, lessThanOrEqualTo(1.3));
      }
    });

    test('usernames distintos generan pitches distintos (varía, no es constante)', () {
      final usernames = List.generate(20, (i) => 'usuario_$i');
      final pitches = usernames.map(pitchForUsername).toSet();
      expect(pitches.length, greaterThan(1));
    });

    test('es insensible a mayúsculas/minúsculas: mismo usuario, mismo pitch', () {
      expect(pitchForUsername('Javier'), equals(pitchForUsername('javier')));
    });

    test('respeta un rango personalizado', () {
      final pitch = pitchForUsername('apliarte', min: 0.5, max: 2.0);
      expect(pitch, greaterThanOrEqualTo(0.5));
      expect(pitch, lessThanOrEqualTo(2.0));
    });
  });
}
