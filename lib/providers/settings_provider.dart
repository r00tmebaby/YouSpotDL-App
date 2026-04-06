import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final service = SettingsService();
  ref.onDispose(() {});
  return service;
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const AppSettings());

  Future<void> load() async {
    await _service.load();
    state = _service.settings;
  }

  Future<void> save(AppSettings settings) async {
    await _service.save(settings);
    state = settings;
  }
}
