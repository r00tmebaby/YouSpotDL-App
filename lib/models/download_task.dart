import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_task.freezed.dart';
part 'download_task.g.dart';

enum DownloadStatus { pending, fetching, downloading, completed, error }

enum Platform { spotify, youtube }

@freezed
class DownloadTask with _$DownloadTask {
  const factory DownloadTask({
    required String id,
    required String url,
    required Platform platform,
    @Default('') String playlistName,
    @Default(0) int totalSongs,
    @Default(0) int downloadedSongs,
    @Default(0) int errorCount,
    @Default(DownloadStatus.pending) DownloadStatus status,
    @Default([]) List<SongProgress> songs,
    String? formatSelector,
    String? outputExt,
  }) = _DownloadTask;

  factory DownloadTask.fromJson(Map<String, dynamic> json) =>
      _$DownloadTaskFromJson(json);
}

@freezed
class SongProgress with _$SongProgress {
  const factory SongProgress({
    required int index,
    required String query,
    @Default(0) double percent,
    @Default('') String speed,
    @Default('') String eta,
    @Default(false) bool completed,
    @Default(false) bool error,
    @Default(false) bool skipped,
    @Default('') String filePath,
  }) = _SongProgress;

  factory SongProgress.fromJson(Map<String, dynamic> json) =>
      _$SongProgressFromJson(json);
}
