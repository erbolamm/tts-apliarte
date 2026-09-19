import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tts_apliarte/controllers/app_controller.dart';
import 'package:tts_apliarte/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getVoices') return <dynamic>[];
        return 1;
      },
    );
  });

  Future<void> waitForInit(AppController controller) async {
    while (!controller.isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  group('AppController: persistencia de sessionId del modo paseo', () {
    test('carga sessionId desde walk_session_id en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'walk_session_id': 'PASEO1',
      });
      final settings = SettingsController();
      await settings.load();

      final controller = AppController(settingsController: settings);
      await waitForInit(controller);

      expect(controller.walkLink.sessionId, 'PASEO1');
      controller.dispose();
      settings.dispose();
    });

    test('carga sessionId con prefijo flutter.walk_session_id como fallback', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.walk_session_id': 'PASEO2',
      });
      final settings = SettingsController();
      await settings.load();

      final controller = AppController(settingsController: settings);
      await waitForInit(controller);

      expect(controller.walkLink.sessionId, 'PASEO2');
      controller.dispose();
      settings.dispose();
    });

    test('setWalkSessionId persiste en SharedPreferences y actualiza walkLink', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController();
      await settings.load();

      final controller = AppController(settingsController: settings);
      await waitForInit(controller);

      expect(controller.walkLink.sessionId, isNull);

      await controller.setWalkSessionId('NUEVA1');
      expect(controller.walkLink.sessionId, 'NUEVA1');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('walk_session_id'), 'NUEVA1');

      await controller.setWalkSessionId('');
      expect(controller.walkLink.sessionId, isNull);
      expect(prefs.getString('walk_session_id'), isNull);

      controller.dispose();
      settings.dispose();
    });
  });
}
