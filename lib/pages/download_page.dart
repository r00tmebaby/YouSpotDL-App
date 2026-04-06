import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme.dart';
import '../core/url_detector.dart';
import '../models/download_format.dart';
import '../models/download_task.dart';
import '../providers/download_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/url_drop_target.dart';
import '../widgets/song_list_tile.dart';
import '../widgets/video_info_card.dart';

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  final _urlController = TextEditingController();
  final Map<String, SongProgress> _lastKnownProgress = {};

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _fetch() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    _lastKnownProgress.clear();
    final token = ref.read(authProvider.notifier).accessToken;
    ref.read(downloadProvider.notifier).fetchUrl(url, token: token);
  }

  Future<void> _startPlaylistDownload() async {
    String? outputDir = ref.read(settingsProvider).downloadDir;

    if (outputDir.isEmpty) {
      final picked = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select download folder',
      );
      if (picked == null) return;
      outputDir = picked;
    }

    final dlState = ref.read(downloadProvider);
    final platform = dlState.detectedType == DetectedUrlType.spotifyPlaylist
        ? Platform.spotify
        : Platform.youtube;

    ref.read(downloadProvider.notifier).startDownload(
          outputDir: outputDir,
          platform: platform,
        );
  }

  Future<void> _handleVideoDownload(DownloadFormat format) async {
    String? outputDir = ref.read(settingsProvider).downloadDir;

    if (outputDir.isEmpty) {
      final picked = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select download folder',
      );
      if (picked == null) return;
      outputDir = picked;
    }

    ref.read(downloadProvider.notifier).startVideoDownload(
          outputDir: outputDir,
          format: format,
        );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _detectedTypeLabel(DetectedUrlType type) {
    switch (type) {
      case DetectedUrlType.spotifyPlaylist:
        return 'Spotify Playlist detected';
      case DetectedUrlType.youtubePlaylist:
        return 'YouTube Playlist detected';
      case DetectedUrlType.youtubeVideo:
        return 'YouTube Video detected';
      case DetectedUrlType.genericVideo:
        return 'yt-dlp supported URL detected';
      case DetectedUrlType.unsupported:
        return 'Unsupported URL';
    }
  }

  IconData _detectedTypeIcon(DetectedUrlType type) {
    switch (type) {
      case DetectedUrlType.spotifyPlaylist:
        return Icons.library_music;
      case DetectedUrlType.youtubePlaylist:
        return Icons.playlist_play;
      case DetectedUrlType.youtubeVideo:
        return Icons.play_circle_outline;
      case DetectedUrlType.genericVideo:
        return Icons.public;
      case DetectedUrlType.unsupported:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dlState = ref.watch(downloadProvider);

    // Show errors as dialogs (deferred to avoid _debugDuringDeviceUpdate)
    ref.listen<DownloadState>(downloadProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showErrorDialog('Error', next.error!);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Download')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supported platforms info
            Tooltip(
              message: 'Powered by yt-dlp — supports 1000+ sites including:\n'
                  'YouTube · SoundCloud · Vimeo · Dailymotion · TikTok\n'
                  'Twitter/X · Instagram · Facebook · Twitch · Bandcamp\n'
                  'Mixcloud · Rumble · Bilibili · and many more',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    'Spotify playlists · YouTube playlists & videos · SoundCloud · Vimeo · 1000+ sites via yt-dlp',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // URL input with drag-and-drop
            UrlDropTarget(
              controller: _urlController,
              onFetch: _fetch,
            ),
            const SizedBox(height: 12),

            // Detected type badge
            if (dlState.detectedType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      _detectedTypeIcon(dlState.detectedType!),
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _detectedTypeLabel(dlState.detectedType!),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Fetching indicator
            if (dlState.isFetching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Video info card for single video (scrollable when tall)
            if (dlState.videoInfo != null)
              Expanded(
                child: SingleChildScrollView(
                  child: VideoInfoCard(
                    videoInfo: dlState.videoInfo!,
                    isDownloading: dlState.tasks.any(
                      (t) => t.url == dlState.videoInfo!.url && t.status == DownloadStatus.downloading,
                    ),
                    downloadTask: dlState.tasks.firstWhere(
                      (t) => t.url == dlState.videoInfo!.url,
                      orElse: () => DownloadTask(
                        id: '',
                        url: dlState.videoInfo!.url,
                        platform: Platform.youtube,
                        playlistName: '',
                        totalSongs: 1,
                        downloadedSongs: 0,
                        status: DownloadStatus.pending,
                        songs: [SongProgress(index: 0, query: dlState.videoInfo!.title)],
                      ),
                    ),
                    onDownload: _handleVideoDownload,
                  ),
                ),
              ),

            // Song list for playlists
            if (dlState.fetchedSongs.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    '${dlState.playlistName ?? "Playlist"} - ${dlState.fetchedSongs.length} songs',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: dlState.activeTasks.isNotEmpty ? null : _startPlaylistDownload,
                    icon: dlState.activeTasks.isNotEmpty
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                          )
                        : const Icon(Icons.download),
                    label: Text(dlState.activeTasks.isNotEmpty ? 'Downloading...' : 'Download All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: dlState.fetchedSongs.length,
                  itemBuilder: (context, index) {
                    final song = dlState.fetchedSongs[index];
                    SongProgress? progress;
                    final songQuery = song.query.isNotEmpty ? song.query : '${song.title} - ${song.artist}';

                    // Find progress by matching song query across all tasks
                    for (final task in dlState.tasks) {
                      for (final sp in task.songs) {
                        if (sp.index == index || sp.query == songQuery) {
                          progress = sp;
                          break;
                        }
                      }
                      if (progress != null) break;
                    }

                    // Cache progress so it persists after task auto-removal
                    if (progress != null) {
                      _lastKnownProgress[songQuery] = progress;
                    } else {
                      progress = _lastKnownProgress[songQuery];
                    }

                    return SongListTile(
                      index: song.index,
                      title: song.title,
                      artist: song.artist,
                      progress: progress?.percent ?? 0,
                      speed: progress?.speed ?? '',
                      completed: progress?.completed ?? false,
                      hasError: progress?.error ?? false,
                      isSkipped: progress?.skipped ?? false,
                      isDownloading: progress != null && !progress.completed && !progress.error && !progress.skipped,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
