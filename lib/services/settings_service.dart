import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  static const _key = 'app_settings';
  SharedPreferences? _prefs;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  final List<void Function(AppSettings)> _listeners = [];

  void addListener(void Function(AppSettings) listener) {
    _listeners.add(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_settings);
    }
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final json = _prefs!.getString(_key);
    if (json != null) {
      _settings = AppSettings.fromJson(jsonDecode(json));
    }
    _notify();
  }

  Future<void> save(AppSettings settings) async {
    _settings = settings;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_key, jsonEncode(settings.toJson()));
    _notify();
  }

  Future<void> updateField(String field, dynamic value) async {
    final map = _settings.toJson();
    map[field] = value;
    await save(AppSettings.fromJson(map));
  }
}
