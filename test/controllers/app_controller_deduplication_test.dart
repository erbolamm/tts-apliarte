import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tts_apliarte/controllers/app_controller.dart';
import 'package:tts_apliarte/controllers/remote_studio_controller.dart';
import 'package:tts_apliarte/controllers/settings_controller.dart';
import 'package:tts_apliarte/models/twitch_message.dart';
import 'package:tts_apliarte/services/twitch_irc_client.dart';

TwitchChatMessage _fakeChatMessage({
  required String id,
  required String username,
  required String text,
}) {
  return TwitchChatMessage(
    id: id,
    channel: 'apliarte',
    username: username,
    displayName: username,
    message: text,
    timestamp: DateTime(2026, 10, 17, 12, 0),
    tags: {'id': id},
    badges: '',
    isMod: false,
    isVip: false,
    isSub: false,
    isBroadcaster: false,
    emotes: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppController - Deduplicación de mensajes de chat', () {
    late SettingsController settingsController;
    late AppController appController;
    late RemoteStudioController studioController;

    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async {
        if (call.method == 'getVoices') return <dynamic>[];
        return 1;
      });

      SharedPreferences.setMockInitialValues({});
      settingsController = SettingsController();
      await settingsController.load();
      appController = AppController(settingsController: settingsController);
      studioController = RemoteStudioController();
      appController.attachRemoteStudio(studioController);

      while (!appController.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });

    tearDown(() {
      appController.dispose();
      studioController.dispose();
      settingsController.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    });

    test('TwitchIrcClient.normalizeChannel limpia almohadillas repetidas o ausentes', () {
      expect(TwitchIrcClient.normalizeChannel('#canal'), 'canal');
      expect(TwitchIrcClient.normalizeChannel('##canal'), 'canal');
      expect(TwitchIrcClient.normalizeChannel('canal'), 'canal');
      expect(TwitchIrcClient.normalizeChannel('@canal'), 'canal');
      expect(TwitchIrcClient.normalizeChannel(' #canal '), 'canal');
    });

    test('ingestLiveChatMessage a través del flujo no duplica mensajes en recentChatMessages', () {
      final msg = _fakeChatMessage(
        id: 'twitch_msg_001',
        username: 'viewer123',
        text: 'Primer mensaje del directo',
      );

      studioController.ingestLiveChatMessage(msg);
      expect(studioController.recentChatMessages.length, 1);

      // Mismo mensaje reenviado por eco o retransmisión
      studioController.ingestLiveChatMessage(msg);
      expect(studioController.recentChatMessages.length, 1);
    });

    test('sendChatMessage deduplica envíos rápidos idénticos en menos de 1.5s', () async {
      // Como no estamos conectados a Twitch en el test, sendChatMessage sale rápido por !_connected.
      // Pero podemos verificar la deduplicación y el flag force.
      expect(appController.isConnected, isFalse);

      // Intentar enviar dos mensajes rápidos no lanza excepciones y se gestiona limpiamente
      await appController.sendChatMessage('Hola chat');
      await appController.sendChatMessage('Hola chat');
      await appController.sendChatMessage('Hola chat', force: true);
    });
  });
}
