// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgressEventImpl _$$ProgressEventImplFromJson(Map<String, dynamic> json) =>
    _$ProgressEventImpl(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$ProgressEventImplToJson(_$ProgressEventImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
      'timestamp': instance.timestamp,
    };
