// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DownloadTaskImpl _$$DownloadTaskImplFromJson(Map<String, dynamic> json) =>
    _$DownloadTaskImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      platform: $enumDecode(_$PlatformEnumMap, json['platform']),
      playlistName: json['playlistName'] as String? ?? '',
      totalSongs: (json['totalSongs'] as num?)?.toInt() ?? 0,
      downloadedSongs: (json['downloadedSongs'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      status:
          $enumDecodeNullable(_$DownloadStatusEnumMap, json['status']) ??
          DownloadStatus.pending,
      songs:
          (json['songs'] as List<dynamic>?)
              ?.map((e) => SongProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      formatSelector: json['formatSelector'] as String?,
      outputExt: json['outputExt'] as String?,
    );

Map<String, dynamic> _$$DownloadTaskImplToJson(_$DownloadTaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'platform': _$PlatformEnumMap[instance.platform]!,
      'playlistName': instance.playlistName,
      'totalSongs': instance.totalSongs,
      'downloadedSongs': instance.downloadedSongs,
      'errorCount': instance.errorCount,
      'status': _$DownloadStatusEnumMap[instance.status]!,
      'songs': instance.songs,
      'formatSelector': instance.formatSelector,
      'outputExt': instance.outputExt,
    };

const _$PlatformEnumMap = {
  Platform.spotify: 'spotify',
  Platform.youtube: 'youtube',
};

const _$DownloadStatusEnumMap = {
  DownloadStatus.pending: 'pending',
  DownloadStatus.fetching: 'fetching',
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.completed: 'completed',
  DownloadStatus.error: 'error',
};

_$SongProgressImpl _$$SongProgressImplFromJson(Map<String, dynamic> json) =>
    _$SongProgressImpl(
      index: (json['index'] as num).toInt(),
      query: json['query'] as String,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      speed: json['speed'] as String? ?? '',
      eta: json['eta'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      error: json['error'] as bool? ?? false,
      skipped: json['skipped'] as bool? ?? false,
      filePath: json['filePath'] as String? ?? '',
    );

Map<String, dynamic> _$$SongProgressImplToJson(_$SongProgressImpl instance) =>
    <String, dynamic>{
      'index': instance.index,
      'query': instance.query,
      'percent': instance.percent,
      'speed': instance.speed,
      'eta': instance.eta,
      'completed': instance.completed,
      'error': instance.error,
      'skipped': instance.skipped,
      'filePath': instance.filePath,
    };
