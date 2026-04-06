import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/download_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear All History', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to delete all download history? This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await clearAllHistory();
              ref.invalidate(historyProvider);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all history',
            onPressed: () => _confirmClearAll(context, ref),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Error loading history', style: TextStyle(color: AppTheme.error)),
              const SizedBox(height: 8),
              Text(e.toString(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'No downloads yet',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryCard(
                entry: entry,
                onDelete: () async {
                  await deleteHistoryEntry(index);
                  ref.invalidate(historyProvider);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onDelete;
  const _HistoryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    // Skipped songs count as successfully processed
    final processed = entry.downloadedSongs + entry.skippedSongs;
    final successRate = entry.totalSongs > 0
        ? ((processed / entry.totalSongs) * 100).round()
        : 0;
    final rateColor = successRate >= 90
        ? AppTheme.success
        : successRate >= 50
            ? AppTheme.warning
            : AppTheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: AppTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.playlistName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateFormat.format(entry.date),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Open folder button
                IconButton(
                  icon: const Icon(Icons.folder_open, color: AppTheme.textSecondary),
                  tooltip: 'Open folder',
                  onPressed: () async {
                    final dir = entry.outputDir;
                    if (Directory(dir).existsSync()) {
                      await Process.run('explorer', [dir]);
                    }
                  },
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
                  tooltip: 'Delete entry',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                if (entry.downloadedSongs > 0) ...[
                  _StatBadge(
                    icon: Icons.check_circle,
                    label: '${entry.downloadedSongs} downloaded',
                    color: AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                ],
                if (entry.skippedSongs > 0) ...[
                  _StatBadge(
                    icon: Icons.skip_next,
                    label: '${entry.skippedSongs} skipped',
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),
                ],
                if (entry.downloadedSongs == 0 && entry.skippedSongs == 0)
                  _StatBadge(
                    icon: Icons.download,
                    label: '0 downloaded',
                    color: AppTheme.textSecondary,
                  ),
                if (entry.errorCount > 0) ...[
                  _StatBadge(
                    icon: Icons.error,
                    label: '${entry.errorCount} failed',
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  '$successRate%',
                  style: TextStyle(
                    color: rateColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('success', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
