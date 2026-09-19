import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/services/screen_off_service.dart';

void main() {
  group('ScreenOffService', () {
    late List<double> brightnessCalls;
    late int resetBrightnessCount;
    late List<bool> wakelockCalls;
    late List<SystemUiMode> systemUiModeCalls;
    late ScreenOffService service;

    setUp(() {
      brightnessCalls = [];
      resetBrightnessCount = 0;
      wakelockCalls = [];
      systemUiModeCalls = [];

      service = ScreenOffService(
        setBrightness: (b) async => brightnessCalls.add(b),
        resetBrightness: () async => resetBrightnessCount++,
        setWakelock: (w) async => wakelockCalls.add(w),
        setSystemUiMode: (m) async => systemUiModeCalls.add(m),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('estado inicial: isScreenOff es false y no hay llamadas', () {
      expect(service.isScreenOff, isFalse);
      expect(brightnessCalls, isEmpty);
      expect(resetBrightnessCount, equals(0));
      expect(wakelockCalls, isEmpty);
      expect(systemUiModeCalls, isEmpty);
    });

    test('enterScreenOffMode activa modo inmersivo, brillo 0, wakelock y notifica', () async {
      var listenerNotified = false;
      service.addListener(() => listenerNotified = true);

      await service.enterScreenOffMode();

      expect(service.isScreenOff, isTrue);
      expect(listenerNotified, isTrue);
      expect(systemUiModeCalls, equals([SystemUiMode.immersiveSticky]));
      expect(brightnessCalls, equals([0.0]));
      expect(wakelockCalls, equals([true]));
      expect(resetBrightnessCount, equals(0));
    });

    test('enterScreenOffMode es idempotente', () async {
      await service.enterScreenOffMode();
      expect(systemUiModeCalls.length, equals(1));
      expect(brightnessCalls.length, equals(1));
      expect(wakelockCalls.length, equals(1));

      // Segunda llamada no debe repetir las acciones
      await service.enterScreenOffMode();
      expect(systemUiModeCalls.length, equals(1));
      expect(brightnessCalls.length, equals(1));
      expect(wakelockCalls.length, equals(1));
    });

    test('exitScreenOffMode restaura modo edgeToEdge, brillo original y libera wakelock', () async {
      await service.enterScreenOffMode();

      var listenerNotified = false;
      service.addListener(() => listenerNotified = true);

      await service.exitScreenOffMode();

      expect(service.isScreenOff, isFalse);
      expect(listenerNotified, isTrue);
      expect(systemUiModeCalls, equals([
        SystemUiMode.immersiveSticky,
        SystemUiMode.edgeToEdge,
      ]));
      expect(resetBrightnessCount, equals(1));
      expect(wakelockCalls, equals([true, false]));
    });

    test('exitScreenOffMode es idempotente cuando la pantalla no está apagada', () async {
      await service.exitScreenOffMode();
      expect(systemUiModeCalls, isEmpty);
      expect(resetBrightnessCount, equals(0));
      expect(wakelockCalls, isEmpty);
    });

    test('dispose restaura ajustes si el servicio se destruye con pantalla apagada', () async {
      await service.enterScreenOffMode();
      expect(service.isScreenOff, isTrue);

      service.dispose();

      expect(service.isScreenOff, isFalse);
      expect(systemUiModeCalls, contains(SystemUiMode.edgeToEdge));
      expect(resetBrightnessCount, equals(1));
      expect(wakelockCalls, contains(false));
    });
  });
}
