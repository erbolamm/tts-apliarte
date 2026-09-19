import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tts_apliarte/controllers/app_controller.dart';
import 'package:tts_apliarte/controllers/settings_controller.dart';
import 'package:tts_apliarte/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppController - ignoredUsers management & persistence', () {
    late SettingsController settingsController;
    late AppController appController;

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

    test('initializes with default ignored users', () {
      expect(appController.isUserIgnored('streamelements'), isTrue);
      expect(appController.isUserIgnored('StreamElements'), isTrue);
      expect(appController.isUserIgnored('@StreamElements'), isTrue);
      expect(appController.isUserIgnored('nightbot'), isTrue);
      expect(appController.isUserIgnored('unknown_chatter'), isFalse);
    });

    test('ignoreUser adds username, persists to SharedPreferences and notifies', () async {
      var notified = false;
      appController.addListener(() => notified = true);

      expect(appController.isUserIgnored('troll_account'), isFalse);

      appController.ignoreUser('@Troll_Account');

      expect(appController.isUserIgnored('troll_account'), isTrue);
      expect(appController.isUserIgnored('TROLL_ACCOUNT'), isTrue);
      expect(appController.settings.ignoredUsers, contains('Troll_Account'));
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('app_settings') ?? '';
      expect(storedJson, contains('Troll_Account'));
    });

    test('ignoreUser avoids duplicate additions case-insensitively', () {
      final initialCount = appController.settings.ignoredUsers.length;

      appController.ignoreUser('NightBot');
      expect(appController.settings.ignoredUsers.length, equals(initialCount));

      appController.ignoreUser('  ');
      expect(appController.settings.ignoredUsers.length, equals(initialCount));
    });

    test('unignoreUser removes user, persists and notifies', () async {
      expect(appController.isUserIgnored('streamelements'), isTrue);

      var notified = false;
      appController.addListener(() => notified = true);

      appController.unignoreUser('@StreamElements');

      expect(appController.isUserIgnored('streamelements'), isFalse);
      expect(appController.settings.ignoredUsers.contains('streamelements'), isFalse);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('app_settings') ?? '';
      expect(storedJson, isNot(contains('"streamelements"')));
    });

    test('resetIgnoredUsers restores defaults', () {
      appController.unignoreUser('streamelements');
      appController.ignoreUser('custom_user');

      expect(appController.isUserIgnored('streamelements'), isFalse);
      expect(appController.isUserIgnored('custom_user'), isTrue);

      appController.resetIgnoredUsers();

      expect(appController.isUserIgnored('streamelements'), isTrue);
      expect(appController.isUserIgnored('custom_user'), isFalse);
      expect(appController.settings.ignoredUsers, equals(AppSettings.defaultIgnoredUsers));
    });
  });
}
