import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/services/walk_link_service.dart';

// Tests de la lógica de estados del WalkLinkService (paso 3 de la cadena
// directo/tts-apliarte). NO mockeamos WebRTC entero: el alcance es
// probar la máquina de estados (idle / requestingPermissions /
// connecting / connected / error) y las precondiciones que la activan
// (URL base, sessionId, pistas activas), no la señalización.
void main() {
  group('WalkLinkService: precondiciones y estados', () {
    test('arranca en idle sin URL ni sessionId', () {
      final svc = WalkLinkService(initialServerBaseUrl: '');
      expect(svc.state, WalkLinkState.idle);
      expect(svc.micEnabled, isFalse);
      expect(svc.camEnabled, isFalse);
      expect(svc.activeTrackCount, 0);
      addTearDown(() async => svc.dispose());
    });

    test('URL vacía no se intenta conectar aunque haya sessionId', () async {
      final svc = WalkLinkService(initialServerBaseUrl: '');
      await svc.setSessionId('PRUEBA1');
      // Sin pistas activas, sigue en idle: nada que enviar.
      expect(svc.state, WalkLinkState.idle);
      addTearDown(() async => svc.dispose());
    });

    test('sessionId vacío cierra cualquier intento previo', () async {
      final svc = WalkLinkService(
        initialServerBaseUrl: 'http://127.0.0.1:8790',
      );
      await svc.setSessionId('PRUEBA1');
      await svc.setSessionId(null);
      expect(svc.state, WalkLinkState.idle);
      addTearDown(() async => svc.dispose());
    });

    test('dispose cierra el estado aunque no haya llegado a conectar',
        () async {
      final svc = WalkLinkService(
        initialServerBaseUrl: 'http://127.0.0.1:8790',
      );
      await svc.setSessionId('PRUEBA1');
      // Sin pistas, no llega a connecting; dispose tiene que ser seguro.
      await svc.dispose();
      // Tras dispose, llamadas adicionales son no-op (no assertemos sobre
      // el estado: el servicio marca _disposed=true y no notifica).
    });

    test('cambio de URL invalida el sessionId actual y vuelve a idle',
        () async {
      final svc = WalkLinkService(
        initialServerBaseUrl: 'http://127.0.0.1:8790',
      );
      await svc.setSessionId('PRUEBA1');
      svc.serverBaseUrl = 'http://192.168.1.5:8790';
      // Después de un microtask, el servicio debe haber hecho teardown.
      await Future<void>.delayed(Duration.zero);
      expect(svc.state, WalkLinkState.idle);
      addTearDown(() async => svc.dispose());
    });

    test('expone sessionId a traves del getter', () async {
      final svc = WalkLinkService(
        initialServerBaseUrl: 'http://127.0.0.1:8790',
      );
      expect(svc.sessionId, isNull);
      await svc.setSessionId('SESION_TEST');
      expect(svc.sessionId, 'SESION_TEST');
      await svc.setSessionId('   ');
      expect(svc.sessionId, isNull);
      addTearDown(() async => svc.dispose());
    });
  });
}