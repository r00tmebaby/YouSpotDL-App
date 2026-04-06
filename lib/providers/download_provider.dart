import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../core/url_detector.dart';
import '../models/download_task.dart';
import '../models/download_format.dart';
import '../models/song.dart';
import '../models/video_info.dart';
import '../services/spotify_api_service.dart';
import '../services/download_service.dart';
import '../services/bootstrap_service.dart';

final spotifyApiProvider = Provider<SpotifyApiService>((ref) => SpotifyApiService());
final downloadServiceProvider = Provider<DownloadService>((ref) => DownloadService());
final bootstrapServiceProvider = Provider<BootstrapService>((ref) => BootstrapService());

/// Live tool-status check — invalidate after auto-setup to refresh.
/// Uses DownloadService (same as toolsInfoProvider) so home page banner
/// and Settings panel always agree — single source of truth.
final toolStatusProvider = FutureProvider<ToolStatus>((ref) async {
  final svc = ref.read(downloadServiceProvider);
  final ytVersion = await svc.getYtdlpVersion();
  final ffVersion = await svc.getFfmpegVersion();
  return ToolStatus(
    ytdlpFound: ytVersion != null,
    ffmpegFound: ffVersion != null,
  );
});

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>((ref) {
  return DownloadNotifier(
    ref,
    ref.read(spotifyApiProvider),
    ref.read(downloadServiceProvider),
  );
});

// History stored as a JSON file next to the exe
final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  return _loadHistory();
});

/// Provides yt-dlp and ffmpeg version strings (null = not found).
final toolsInfoProvider = FutureProvider<Map<String, String?>>((ref) async {
  final svc = ref.read(downloadServiceProvider);
  final ytVer = await svc.getYtdlpVersion();
  final ffVer = await svc.getFfmpegVersion();
  return {'ytdlp': ytVer, 'ffmpeg': ffVer};
});

Future<String> _historyPath() async {
  final exeDir = p.dirname(io.Platform.resolvedExecutable);
  // Walk up to find project root that contains dlp / yt-dlp (any platform)
  var dir = exeDir;
  for (var i = 0; i < 10; i++) {
    for (final name in ['dlp.exe', 'yt-dlp.exe', 'dlp', 'yt-dlp']) {
      if (io.File(p.join(dir, name)).existsSync()) {
        return p.join(dir, '.youspotdl_history.json');
      }
    }
    final parent = p.dirname(dir);
    if (parent == dir) break;
    dir = parent;
  }
  return p.join(exeDir, '.youspotdl_history.json');
}

Future<List<HistoryEntry>> _loadHistory() async {
  final path = await _historyPath();
  final file = io.File(path);
  if (!file.existsSync()) return [];
  try {
    final data = jsonDecode(await file.readAsString()) as List<dynamic>;
    return data.map((e) => HistoryEntry.fromMap(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
}

Future<void> _saveHistory(List<HistoryEntry> entries) async {
  final path = await _historyPath();
  final file = io.File(path);
  await file.writeAsString(jsonEncode(entries.map((e) => e.toMap()).toList()));
}

Future<void> deleteHistoryEntry(int index) async {
  final history = await _loadHistory();
  if (index >= 0 && index < history.length) {
    history.removeAt(index);
    await _saveHistory(history);
  }
}

Future<void> clearAllHistory() async {
  await _saveHistory([]);
}

class HistoryEntry {
  final String playlistName;
  final int totalSongs;
  final int downloadedSongs;
  final int skippedSongs;
  final int errorCount;
  final String outputDir;
  final DateTime date;

  HistoryEntry({
    required this.playlistName,
    required this.totalSongs,
    required this.downloadedSongs,
    required this.skippedSongs,
    required this.errorCount,
    required this.outputDir,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'playlist_name': playlistName,
    'total_songs': totalSongs,
    'downloaded_songs': downloadedSongs,
    'skipped_songs': skippedSongs,
    'error_count': errorCount,
    'output_dir': outputDir,
    'date': date.toIso8601String(),
  };

  HistoryEntry.fromMap(Map<String, dynamic> m)
      : playlistName = m['playlist_name'] as String,
        totalSongs = m['total_songs'] as int,
        downloadedSongs = m['downloaded_songs'] as int,
        skippedSongs = m['skipped_songs'] as int,
        errorCount = m['error_count'] as int,
        outputDir = m['output_dir'] as String,
        date = DateTime.parse(m['date'] as String);
}

class DownloadState {
  final List<DownloadTask> tasks;
  final List<Song> fetchedSongs;
  final String? playlistName;
  final bool isFetching;
  final String? error;
  final VideoInfo? videoInfo;
  final DetectedUrlType? detectedType;

  /// Only active (not completed) tasks
  List<DownloadTask> get activeTasks =>
      tasks.where((t) => t.status != DownloadStatus.completed).toList();

  const DownloadState({
    this.tasks = const [],
    this.fetchedSongs = const [],
    this.playlistName,
    this.isFetching = false,
    this.error,
    this.videoInfo,
    this.detectedType,
  });

  DownloadState copyWith({
    List<DownloadTask>? tasks,
    List<Song>? fetchedSongs,
    String? playlistName,
    bool? isFetching,
    String? error,
    VideoInfo? videoInfo,
    DetectedUrlType? detectedType,
    bool clearVideoInfo = false,
    bool clearFetchedSongs = false,
  }) {
    return DownloadState(
      tasks: tasks ?? this.tasks,
      fetchedSongs: clearFetchedSongs ? const [] : (fetchedSongs ?? this.fetchedSongs),
      playlistName: playlistName ?? this.playlistName,
      isFetching: isFetching ?? this.isFetching,
      error: error,
      videoInfo: clearVideoInfo ? null : (videoInfo ?? this.videoInfo),
      detectedType: detectedType ?? this.detectedType,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  final Ref _ref;
  final SpotifyApiService _spotifyApi;
  final DownloadService _downloadService;
  final _uuid = const Uuid();

  DownloadNotifier(this._ref, this._spotifyApi, this._downloadService) : super(const DownloadState());

  /// Auto-detect URL type and route to the correct fetch method.
  Future<void> fetchUrl(String url, {String? token}) async {
    final detected = detectUrlType(url);
    state = state.copyWith(
      isFetching: true,
      error: null,
      detectedType: detected,
      clearVideoInfo: true,
      clearFetchedSongs: true,
    );

    try {
      switch (detected) {
        case DetectedUrlType.spotifyPlaylist:
          // ── Try yt-dlp first — works for public playlists, no credentials needed ──
          final ytdlpResult = await _downloadService.fetchSpotifyPlaylistViaYtdlp(url);
          if (ytdlpResult != null) {
            final trackList = (ytdlpResult['tracks'] as List).cast<Map<String, String>>();
            final pName = ytdlpResult['playlistName'] as String;
            final songs = <Song>[
              for (var i = 0; i < trackList.length; i++)
                Song(
                  title: trackList[i]['title']!,
                  artist: trackList[i]['artist']!,
                  index: i,
                  query: '${trackList[i]['title']} - ${trackList[i]['artist']}',
                ),
            ];
            state = state.copyWith(isFetching: false, fetchedSongs: songs, playlistName: pName);
          } else {
            // ── Fall back to Spotify API OAuth (required for private playlists) ──
            if (token == null) {
              throw Exception(
                'Could not fetch this Spotify playlist automatically.\n'
                'If it is a private playlist, connect your Spotify account in Settings.',
              );
            }
            final playlistId = url.split('/').last.split('?').first;
            final plData = await _spotifyApi.getPlaylist(token, playlistId);
            final playlistName = plData['name'] as String? ?? 'Unknown_Playlist';
            final tracks = await _spotifyApi.getPlaylistTracks(token, playlistId);
            final songs = <Song>[];
            for (var i = 0; i < tracks.length; i++) {
              songs.add(Song(
                title: tracks[i]['title'] as String,
                artist: tracks[i]['artist'] as String,
                index: i,
                query: '${tracks[i]['title']} - ${tracks[i]['artist']}',
              ));
            }
            state = state.copyWith(isFetching: false, fetchedSongs: songs, playlistName: playlistName);
          }

        case DetectedUrlType.youtubePlaylist:
          final entries = await _downloadService.fetchYouTubePlaylist(url);
          final songs = <Song>[];
          for (var i = 0; i < entries.length; i++) {
            songs.add(Song(
              title: entries[i]['title']!,
              artist: 'YouTube',
              index: i,
              query: entries[i]['url']!,   // download by direct URL, not ytsearch
            ));
          }
          state = state.copyWith(isFetching: false, fetchedSongs: songs, playlistName: 'YouTube Playlist');

        case DetectedUrlType.youtubeVideo:
          final info = await _downloadService.fetchVideoInfo(url);
          state = state.copyWith(isFetching: false, videoInfo: info);

        case DetectedUrlType.genericVideo:
          // Any other yt-dlp-supported URL (SoundCloud, Vimeo, TikTok, etc.)
          final info = await _downloadService.fetchVideoInfo(url);
          state = state.copyWith(isFetching: false, videoInfo: info);

        case DetectedUrlType.unsupported:
          throw Exception('Unsupported URL. Use a Spotify playlist, YouTube playlist, YouTube video, or any URL supported by yt-dlp.');
      }
    } catch (e) {
      state = state.copyWith(isFetching: false, error: e.toString());
    }
  }

  Future<void> fetchPlaylist({
    required String url,
    required Platform platform,
    String? token,
  }) async {
    state = state.copyWith(isFetching: true, error: null, fetchedSongs: [], clearVideoInfo: true);

    try {
      if (platform == Platform.spotify) {
        // Try yt-dlp first (public playlists — no credentials needed)
        final ytdlpResult = await _downloadService.fetchSpotifyPlaylistViaYtdlp(url);
        if (ytdlpResult != null) {
          final trackList = (ytdlpResult['tracks'] as List).cast<Map<String, String>>();
          final pName = ytdlpResult['playlistName'] as String;
          final songs = <Song>[
            for (var i = 0; i < trackList.length; i++)
              Song(
                title: trackList[i]['title']!,
                artist: trackList[i]['artist']!,
                index: i,
                query: '${trackList[i]['title']} - ${trackList[i]['artist']}',
              ),
          ];
          state = state.copyWith(isFetching: false, fetchedSongs: songs, playlistName: pName);
        } else {
          // Fall back to Spotify API OAuth (private playlists)
          if (token == null) throw Exception('Spotify token required for private playlists.');
          final playlistId = url.split('/').last.split('?').first;
          final plData = await _spotifyApi.getPlaylist(token, playlistId);
          final playlistName = plData['name'] as String? ?? 'Unknown_Playlist';
          final tracks = await _spotifyApi.getPlaylistTracks(token, playlistId);
          final songs = <Song>[];
          for (var i = 0; i < tracks.length; i++) {
            songs.add(Song(
              title: tracks[i]['title'] as String,
              artist: tracks[i]['artist'] as String,
              index: i,
              query: '${tracks[i]['title']} - ${tracks[i]['artist']}',
            ));
          }
          state = state.copyWith(isFetching: false, fetchedSongs: songs, playlistName: playlistName);
        }
      } else {
        final entries = await _downloadService.fetchYouTubePlaylist(url);
        final songs = <Song>[];
        for (var i = 0; i < entries.length; i++) {
          songs.add(Song(
            title: entries[i]['title']!,
            artist: 'YouTube',
            index: i,
            query: entries[i]['url']!,
          ));
        }
        state = state.copyWith(isFetching: false, fetchedSongs: songs, playlistName: 'YouTube Playlist');
      }
    } catch (e) {
      state = state.copyWith(isFetching: false, error: e.toString());
    }
  }

  void startDownload({
    required String outputDir,
    required Platform platform,
    int concurrency = 8,
  }) {
    final songs = state.fetchedSongs;
    if (songs.isEmpty) return;

    final playlistName = state.playlistName ?? 'Playlist';
    final outputFolder = p.join(outputDir, playlistName);
    io.Directory(outputFolder).createSync(recursive: true);

    final task = DownloadTask(
      id: _uuid.v4(),
      url: '',
      platform: platform,
      playlistName: playlistName,
      totalSongs: songs.length,
      songs: songs
          .map((s) => SongProgress(
                index: s.index,
                query: s.query.isNotEmpty ? s.query : '${s.title} - ${s.artist}',
              ))
          .toList(),
      status: DownloadStatus.downloading,
    );

    state = state.copyWith(tasks: [...state.tasks, task]);
    _runDownloads(task.id, songs, outputFolder, concurrency, outputFolder);
  }

  /// Start downloading a single video with the chosen format.
  void startVideoDownload({
    required String outputDir,
    required DownloadFormat format,
  }) {
    final info = state.videoInfo;
    if (info == null) return;

    io.Directory(outputDir).createSync(recursive: true);

    final task = DownloadTask(
      id: _uuid.v4(),
      url: info.url,
      platform: Platform.youtube,
      playlistName: info.title,
      totalSongs: 1,
      songs: [SongProgress(index: 0, query: info.title)],
      status: DownloadStatus.downloading,
      formatSelector: format.ytDlpSelector,
      outputExt: format.outputExt,
    );

    state = state.copyWith(tasks: [...state.tasks, task]);
    _processVideo(task.id, info.url, outputDir, format);
  }

  Future<void> _processVideo(String taskId, String url, String outputDir, DownloadFormat format) async {
    String? downloadError;

    await for (final progress in _downloadService.downloadVideo(
      url: url,
      outputDir: outputDir,
      formatSelector: format.ytDlpSelector,
      outputExt: format.outputExt,
      audioOnly: format.audioOnly,
      index: 0,
    )) {
      _updateSongProgress(taskId, progress);
      if (progress.status == SongDownloadStatus.error) {
        downloadError = progress.error ?? 'Video download failed.';
      }
    }

    // Surface the error to the user via the global error state (triggers dialog)
    if (downloadError != null && mounted) {
      state = state.copyWith(error: downloadError);
    }

    _markTaskCompleted(taskId, outputDir);
  }

  void _runDownloads(
    String taskId,
    List<Song> songs,
    String outputFolder,
    int concurrency,
    String baseOutputDir,
  ) {
    var running = 0;
    final queue = List<Song>.from(songs);

    void startNext() {
      while (running < concurrency && queue.isNotEmpty) {
        final song = queue.removeAt(0);
        running++;
        _processSong(taskId, song, outputFolder).whenComplete(() {
          running--;
          if (queue.isEmpty && running == 0) {
            _markTaskCompleted(taskId, baseOutputDir);
          } else {
            startNext();
          }
        });
      }
    }

    startNext();
  }

  Future<void> _processSong(String taskId, Song song, String outputFolder) async {
    final queryStr = song.query.isNotEmpty ? song.query : '${song.title} - ${song.artist}';
    await for (final progress in _downloadService.downloadSong(
      query: queryStr,
      outputDir: outputFolder,
      index: song.index,
      displayTitle: song.title,
    )) {
      _updateSongProgress(taskId, progress);
    }
  }

  void _updateSongProgress(String taskId, SongDownloadProgress progress) {
    final tasks = [...state.tasks];
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    var task = tasks[idx];
    final songList = List<SongProgress>.from(task.songs);

    final i = progress.index;
    if (i < songList.length) {
      final isSkipped = progress.status == SongDownloadStatus.skipped;
      final isComplete = progress.status == SongDownloadStatus.completed;
      final isError = progress.status == SongDownloadStatus.error;

      songList[i] = SongProgress(
        index: i,
        query: songList[i].query,
        percent: (isComplete || isSkipped) ? 100.0 : progress.percent,
        speed: progress.speed,
        eta: progress.eta,
        completed: isComplete,
        skipped: isSkipped,
        error: isError,
        filePath: progress.filePath ?? '',
      );
    }

    // Both downloaded and skipped count toward progress
    final downloaded = songList.where((s) => s.completed || s.skipped).length;
    final errors = songList.where((s) => s.error).length;

    tasks[idx] = DownloadTask(
      id: task.id,
      url: task.url,
      platform: task.platform,
      playlistName: task.playlistName,
      totalSongs: task.totalSongs,
      downloadedSongs: downloaded,
      errorCount: errors,
      status: task.status,
      songs: songList,
    );

    state = state.copyWith(tasks: tasks);
  }

  Future<void> _markTaskCompleted(String taskId, String outputDir) async {
    final tasks = [...state.tasks];
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;

    final task = tasks[idx];

    // Build final task with completed status
    tasks[idx] = DownloadTask(
      id: task.id,
      url: task.url,
      platform: task.platform,
      playlistName: task.playlistName,
      totalSongs: task.totalSongs,
      downloadedSongs: task.totalSongs,  // All songs completed
      errorCount: task.errorCount,
      status: DownloadStatus.completed,
      songs: task.songs,
    );
    state = state.copyWith(tasks: tasks);

    // Save to history, then refresh the history provider so the page updates immediately
    try {
      final history = await _loadHistory();
      final trueDownloaded = task.songs.where((s) => s.completed).length;
      final trueSkipped   = task.songs.where((s) => s.skipped).length;
      history.insert(0, HistoryEntry(
        playlistName: task.playlistName,
        totalSongs: task.totalSongs,
        downloadedSongs: trueDownloaded,
        skippedSongs: trueSkipped,
        errorCount: task.errorCount,
        outputDir: outputDir,
        date: DateTime.now(),
      ));
      await _saveHistory(history);
      // Invalidate so historyProvider re-runs and the history page shows the new entry
      _ref.invalidate(historyProvider);
    } catch (_) {}

    // Auto-remove completed task after a longer delay so users can see it
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        removeTask(taskId);
      }
    });
  }

  void removeTask(String taskId) {
    state = state.copyWith(tasks: state.tasks.where((t) => t.id != taskId).toList());
  }
}
