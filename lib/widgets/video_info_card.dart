import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/download_format.dart';
import '../models/video_info.dart';
import '../models/download_task.dart';

class VideoInfoCard extends StatefulWidget {
  final VideoInfo videoInfo;
  final bool isDownloading;
  final void Function(DownloadFormat format) onDownload;
  final DownloadTask? downloadTask;

  const VideoInfoCard({
    super.key,
    required this.videoInfo,
    this.isDownloading = false,
    required this.onDownload,
    this.downloadTask,
  });

  @override
  State<VideoInfoCard> createState() => _VideoInfoCardState();
}

class _VideoInfoCardState extends State<VideoInfoCard> {
  DownloadFormat? _selectedFormat;

  @override
  void initState() {
    super.initState();
    _selectedFormat = DownloadFormat.audioFormats.first;
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.videoInfo;
    final downloading = widget.isDownloading;
    final task = widget.downloadTask;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail + metadata row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      info.thumbnail!,
                      width: 160,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.play_circle_outline, color: AppTheme.textSecondary, size: 40),
                      ),
                    ),
                  ),
                if (info.thumbnail != null) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (info.uploader != null)
                        Text(
                          info.uploader!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(info.duration),
                        style: TextStyle(
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Format selection
            const Text(
              'Audio',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            ...DownloadFormat.audioFormats.map((f) => _buildRadioTile(f, downloading)),
            const SizedBox(height: 12),
            const Text(
              'Video',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            ...DownloadFormat.videoFormats.map((f) => _buildRadioTile(f, downloading)),

            const SizedBox(height: 20),

            // Download button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: downloading
                    ? null
                    : (_selectedFormat != null
                        ? () => widget.onDownload(_selectedFormat!)
                        : null),
                icon: downloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black54,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  downloading
                      ? 'Downloading...'
                      : 'Download as ${_selectedFormat?.label ?? ''}',
                ),
              ),
            ),

            // Progress bar and info during download
            if (downloading && task != null && task.songs.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${task.songs[0].percent.toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.songs[0].speed.isNotEmpty)
                        Text(
                          task.songs[0].speed,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: task.songs[0].percent / 100.0,
                  ),
                  if (task.songs[0].eta.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'ETA: ${task.songs[0].eta}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(DownloadFormat format, bool disabled) {
    return InkWell(
      onTap: disabled ? null : () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Radio<DownloadFormat>(
              value: format,
              groupValue: _selectedFormat,
              onChanged: disabled
                  ? null
                  : (f) {
                      if (f != null) setState(() => _selectedFormat = f);
                    },
              activeColor: AppTheme.primary,
              visualDensity: VisualDensity.compact,
            ),
            Text(
              format.label,
              style: TextStyle(
                color: disabled ? AppTheme.textSecondary : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
