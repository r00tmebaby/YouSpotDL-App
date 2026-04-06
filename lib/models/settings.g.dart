// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      clientId: json['clientId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      redirectUri:
          json['redirectUri'] as String? ?? 'http://127.0.0.1:8888/callback',
      downloadDir: json['downloadDir'] as String? ?? '',
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 8,
      audioQuality: json['audioQuality'] as String? ?? '0',
      isDarkMode: json['isDarkMode'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'clientSecret': instance.clientSecret,
      'redirectUri': instance.redirectUri,
      'downloadDir': instance.downloadDir,
      'concurrency': instance.concurrency,
      'audioQuality': instance.audioQuality,
      'isDarkMode': instance.isDarkMode,
    };
