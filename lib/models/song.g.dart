// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
  title: json['title'] as String,
  artist: json['artist'] as String,
  query: json['query'] as String? ?? '',
  index: (json['index'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'artist': instance.artist,
      'query': instance.query,
      'index': instance.index,
    };
