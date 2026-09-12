import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsController extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults();
  bool _ready = false;

  AppSettings get settings => _settings;
  bool get isReady => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_settings');
    if (raw != null && raw.isNotEmpty) {
      _settings = AppSettings.fromStorageString(raw);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _settings = AppSettings.defaults();
    notifyListeners();
    await _persist();
  }

  Future<void> update(AppSettings updated) async {
    _settings = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> updateWith(AppSettings Function(AppSettings current) updateFn) async {
    _settings = updateFn(_settings);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', _settings.toStorageString());
  }
}
