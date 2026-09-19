import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tts_apliarte/controllers/app_controller.dart';
import 'package:tts_apliarte/controllers/settings_controller.dart';
import 'package:tts_apliarte/services/foreground_service.dart';

class FakeForegroundService extends ForegroundService {
  FakeForegroundService() : super(enablePlatformCheck: false);

  int startOrUpdateCalls = 0;
  int stopCalls = 0;
  String? lastTitle;
  String? lastText;
  bool running = false;

  @override
  bool get isRunning => running;

  @override
  Future<void> init() async {}

  @override
  Future<bool> startOrUpdate({
    required String title,
    required String text,
  }) async {
    startOrUpdateCalls++;
    lastTitle = title;
    lastText = text;
    running = true;
    return true;
  }

  @override
  Future<bool> stop() async {
    stopCalls++;
    running = false;
    return true;
  }
}

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

  group('ForegroundService: comportamiento base', () {
    test('en entornos de prueba de escritorio isSupported es false por defecto', () {
      final service = ForegroundService();
      expect(service.isSupported, isFalse);
      expect(service.isRunning, isFalse);
    });

    test('startOrUpdate y stop son seguros y devuelven true en plataformas no soportadas', () async {
      final service = ForegroundService();
      final startRes = await service.startOrUpdate(
        title: 'TTS ApliArte',
        text: 'Prueba',
      );
      expect(startRes, isTrue);
      expect(service.isRunning, isTrue);

      final stopRes = await service.stop();
      expect(stopRes, isTrue);
      expect(service.isRunning, isFalse);
    });
  });

  group('AppController: sincronización con ForegroundService', () {
    test('arranca detenido si no hay chat, dictado ni enlace activo', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController();
      await settings.load();

      final fakeFs = FakeForegroundService();
      final controller = AppController(
        settingsController: settings,
        foregroundService: fakeFs,
      );
      await waitForInit(controller);

      expect(fakeFs.running, isFalse);
      expect(fakeFs.stopCalls, greaterThanOrEqualTo(1));

      controller.dispose();
      settings.dispose();
    });

    test('al activar walkLink (mic o cam) se inicia el servicio en segundo plano', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController();
      await settings.load();

      final fakeFs = FakeForegroundService();
      final controller = AppController(
        settingsController: settings,
        foregroundService: fakeFs,
      );
      await waitForInit(controller);

      // Simular cambio de ajustes con walkMicEnabled
      await settings.updateWith((s) => s.copyWith(walkMicEnabled: true));
      expect(fakeFs.startOrUpdateCalls, greaterThanOrEqualTo(1));
      expect(fakeFs.running, isTrue);
      expect(fakeFs.lastTitle, 'TTS ApliArte');
      expect(fakeFs.lastText, contains('Modo paseo'));

      // Desactivar walkMicEnabled detiene el servicio si no hay chat
      await settings.updateWith((s) => s.copyWith(walkMicEnabled: false));
      expect(fakeFs.running, isFalse);

      controller.dispose();
      settings.dispose();
    });

    test('dispose de AppController detiene el ForegroundService', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController();
      await settings.load();

      final fakeFs = FakeForegroundService();
      final controller = AppController(
        settingsController: settings,
        foregroundService: fakeFs,
      );
      await waitForInit(controller);

      final prevStopCalls = fakeFs.stopCalls;
      controller.dispose();
      expect(fakeFs.stopCalls, greaterThan(prevStopCalls));
      expect(fakeFs.running, isFalse);

      settings.dispose();
    });
  });
}
