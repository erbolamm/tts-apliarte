import 'package:flutter_test/flutter_test.dart';
import 'package:tts_apliarte/models/app_settings.dart';

void main() {
  group('AppSettings - ignoredUsers persistence and defaults', () {
    test('default settings contain defaultIgnoredUsers', () {
      final settings = AppSettings.defaults();

      expect(settings.ignoredUsers, contains('streamelements'));
      expect(settings.ignoredUsers, contains('nightbot'));
      expect(settings.ignoredUsers, contains('streamlabs'));
      expect(settings.ignoredUsers, contains('pepitoelpapas'));
      expect(settings.ignoredUsers.length, equals(AppSettings.defaultIgnoredUsers.length));
    });

    test('toJson and fromJson preserve custom ignoredUsers list', () {
      final custom = AppSettings.defaults().copyWith(
        ignoredUsers: ['spambot1', 'spambot2', 'nightbot'],
      );

      final json = custom.toJson();
      expect(json['ignoredUsers'], equals(['spambot1', 'spambot2', 'nightbot']));

      final restored = AppSettings.fromJson(json);
      expect(restored.ignoredUsers, equals(['spambot1', 'spambot2', 'nightbot']));
    });

    test('fromJson falls back to defaultIgnoredUsers when key is absent', () {
      final json = AppSettings.defaults().toJson();
      json.remove('ignoredUsers');

      final restored = AppSettings.fromJson(json);
      expect(restored.ignoredUsers, equals(AppSettings.defaultIgnoredUsers));
    });

    test('toStorageString and fromStorageString persist ignoredUsers', () {
      final custom = AppSettings.defaults().copyWith(
        ignoredUsers: ['annoying_user', 'troll_bot'],
      );

      final storageStr = custom.toStorageString();
      final loaded = AppSettings.fromStorageString(storageStr);

      expect(loaded.ignoredUsers, equals(['annoying_user', 'troll_bot']));
    });
  });
}
