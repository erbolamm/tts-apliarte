import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tts_apliarte/controllers/app_controller.dart';
import 'package:tts_apliarte/controllers/settings_controller.dart';
import 'package:tts_apliarte/models/app_settings.dart';
import 'package:tts_apliarte/ui/widgets/walk_link_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Modo paseo - Botón apagar pantalla e integración en AppController', () {
    late SettingsController settingsController;
    late AppController appController;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
        if (call.method == 'getVoices') return <dynamic>[];
        return 1;
      });

      SharedPreferences.setMockInitialValues({
        'app_settings': AppSettings.defaults().copyWith(
          scenesServerBaseUrl: 'http://127.0.0.1:4455',
        ).toStorageString(),
      });
      settingsController = SettingsController();
      await settingsController.load();
      appController = AppController(settingsController: settingsController);
      while (!appController.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    tearDown(() {
      appController.dispose();
      settingsController.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('AppController delega en ScreenOffService y notifica listeners', () async {
      var notified = false;
      appController.addListener(() => notified = true);

      expect(appController.isScreenOff, isFalse);

      await appController.enterScreenOffMode();
      expect(appController.isScreenOff, isTrue);
      expect(notified, isTrue);

      notified = false;
      await appController.exitScreenOffMode();
      expect(appController.isScreenOff, isFalse);
      expect(notified, isTrue);
    });

    testWidgets('WalkLinkCard renderiza el botón de apagar pantalla y lo acciona', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsController>.value(value: settingsController),
            ChangeNotifierProvider<AppController>.value(value: appController),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WalkLinkCard(appController: appController),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe encontrarse el botón con icono de encendido/apagado y texto de ahorro
      final buttonFinder = find.widgetWithText(FilledButton, 'Apagar pantalla (ahorro batería)');
      expect(buttonFinder, findsOneWidget);

      expect(appController.isScreenOff, isFalse);

      // Pulsamos el botón de apagar pantalla
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(appController.isScreenOff, isTrue);
    });
  });
}
