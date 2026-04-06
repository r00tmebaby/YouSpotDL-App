import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/download_task.dart';

class SongListTile extends StatelessWidget {
  final int index;
  final String title;
  final String artist;
  final double progress;
  final String speed;
  final bool completed;
  final bool hasError;
  final bool isDownloading;
  final bool isSkipped;

  const SongListTile({
    super.key,
    required this.index,
    required this.title,
    required this.artist,
    this.progress = 0,
    this.speed = '',
    this.completed = false,
    this.hasError = false,
    this.isDownloading = false,
    this.isSkipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor;
    if (completed) {
      titleColor = AppTheme.success;
    } else if (isSkipped) {
      titleColor = Colors.amber;
    } else if (hasError) {
      titleColor = AppTheme.error;
    } else {
      titleColor = AppTheme.textPrimary;
    }

    return ListTile(
      leading: SizedBox(
        width: 32,
        child: Center(
          child: _buildStatusIcon(),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          decoration: (completed || isSkipped) ? TextDecoration.lineThrough : null,
          decorationColor: titleColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: isDownloading && progress > 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppTheme.surfaceVariant,
                ),
                const SizedBox(height: 2),
                Text(
                  '${progress.toStringAsFixed(1)}% ${speed.isNotEmpty ? "· $speed" : ""}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            )
          : Text(
              isSkipped ? 'Skipped — already downloaded' : artist,
              style: TextStyle(
                fontSize: 12,
                color: isSkipped ? Colors.amber : AppTheme.textSecondary,
              ),
            ),
    );
  }

  Widget _buildStatusIcon() {
    if (completed) return const Icon(Icons.check_circle, color: AppTheme.success, size: 20);
    if (isSkipped) return const Icon(Icons.skip_next, color: Colors.amber, size: 20);
    if (hasError) return const Icon(Icons.error, color: AppTheme.error, size: 20);
    if (isDownloading) return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    return Text(
      '${index + 1}',
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    );
  }
}
