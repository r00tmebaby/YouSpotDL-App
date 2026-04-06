import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/download_task.dart';
import '../providers/download_provider.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(downloadProvider);
    // Show all tasks including recently completed ones
    final tasks = state.tasks;

    return Scaffold(
      appBar: AppBar(title: const Text('Download Queue')),
      body: tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No downloads in queue',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskCard(
                  task: task,
                  onRemove: () =>
                      ref.read(downloadProvider.notifier).removeTask(task.id),
                );
              },
            ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback onRemove;

  const _TaskCard({required this.task, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    // For single video downloads, show actual progress percent
    // For playlists, show completed song count
    double progress = 0.0;
    String progressText;

    if (task.totalSongs == 1 && task.songs.isNotEmpty) {
      // Single video - use the song's progress percent
      progress = task.songs[0].percent / 100.0;
      progressText = '${task.songs[0].percent.toInt()}%';
    } else {
      // Playlist - use song count
      progress = (task.downloadedSongs + task.errorCount) / task.totalSongs;
      progressText = '${task.downloadedSongs}/${task.totalSongs} songs';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(status: task.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.playlistName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        progressText,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (task.totalSongs == 1 && task.songs.isNotEmpty && task.songs[0].speed.isNotEmpty)
                        Text(
                          '${task.songs[0].speed} - ETA: ${task.songs[0].eta}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: onRemove,
                ),
              ],
            ),
            if (task.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      DownloadStatus.pending => (Icons.schedule, AppTheme.textSecondary, 'Pending'),
      DownloadStatus.fetching => (Icons.search, AppTheme.warning, 'Fetching'),
      DownloadStatus.downloading => (Icons.downloading, AppTheme.primary, 'Downloading'),
      DownloadStatus.completed => (Icons.check_circle, AppTheme.success, 'Done'),
      DownloadStatus.error => (Icons.error, AppTheme.error, 'Error'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
