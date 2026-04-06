import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('') String clientId,
    @Default('') String clientSecret,
    @Default('http://127.0.0.1:8888/callback') String redirectUri,
    @Default('') String downloadDir,
    @Default(8) int concurrency,
    @Default('0') String audioQuality,
    @Default(false) bool isDarkMode,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
