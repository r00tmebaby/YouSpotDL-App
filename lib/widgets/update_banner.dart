import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/update_provider.dart';

/// Compact strip shown above every page that surfaces update activity: the
/// result of a previous app update, yt-dlp installs and the app update offer.
/// It renders nothing when there is nothing to report.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previous = ref.watch(previousUpdateResultProvider);
    final ytdlp = ref.watch(ytdlpUpdaterProvider);
    final app = ref.watch(appUpdateProvider);

    final rows = <Widget>[];

    if (previous != null) {
      rows.add(
        _BannerRow(
          message: previous,
          onClose: () =>
              ref.read(previousUpdateResultProvider.notifier).state = null,
        ),
      );
    }

    switch (ytdlp.phase) {
      case YtdlpUpdatePhase.downloading:
        rows.add(
          _BannerRow(
            message: ytdlp.message ?? 'Updating yt-dlp...',
            progress: ytdlp.fraction,
          ),
        );
      case YtdlpUpdatePhase.installed:
      case YtdlpUpdatePhase.failed:
        rows.add(
          _BannerRow(
            message: ytdlp.message ?? 'yt-dlp update finished',
            isError: ytdlp.phase == YtdlpUpdatePhase.failed,
            onClose: () =>
                ref.read(ytdlpUpdaterProvider.notifier).acknowledge(),
          ),
        );
      case YtdlpUpdatePhase.idle:
      case YtdlpUpdatePhase.checking:
      case YtdlpUpdatePhase.upToDate:
        break;
    }

    final notifier = ref.read(appUpdateProvider.notifier);
    final release = app.release;
    if (app.showBanner && release != null) {
      switch (app.phase) {
        case AppUpdatePhase.available:
          rows.add(
            _BannerRow(
              message: notifier.supportsInPlaceUpdate
                  ? 'YouSpotDL ${release.version} is available'
                  : 'YouSpotDL ${release.version} is available. '
                      'Download it from the release page and install it manually.',
              actions: [
                if (notifier.supportsInPlaceUpdate)
                  TextButton(
                    onPressed: notifier.openReleasePage,
                    child: const Text('Release notes'),
                  ),
                TextButton(
                  onPressed: notifier.later,
                  child: const Text('Later'),
                ),
                FilledButton(
                  onPressed: notifier.startUpdate,
                  child: Text(notifier.supportsInPlaceUpdate
                      ? 'Update now'
                      : 'Open release page'),
                ),
              ],
            ),
          );
        case AppUpdatePhase.downloading:
        case AppUpdatePhase.launching:
          rows.add(
            _BannerRow(
              message: app.message ?? 'Updating YouSpotDL...',
              progress: app.phase == AppUpdatePhase.downloading
                  ? app.fraction
                  : null,
              showIndeterminate: app.phase == AppUpdatePhase.launching,
            ),
          );
        case AppUpdatePhase.failed:
          rows.add(
            _BannerRow(
              message: app.message ?? 'The update failed',
              isError: true,
              actions: [
                TextButton(
                  onPressed: notifier.openReleasePage,
                  child: const Text('Open release page'),
                ),
                TextButton(
                  onPressed: notifier.later,
                  child: const Text('Later'),
                ),
              ],
            ),
          );
        case AppUpdatePhase.idle:
        case AppUpdatePhase.checking:
        case AppUpdatePhase.upToDate:
          break;
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

/// One banner line: message, optional progress bar, action buttons and an
/// optional dismiss button.
class _BannerRow extends StatelessWidget {
  final String message;
  final bool isError;
  final double? progress;
  final bool showIndeterminate;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const _BannerRow({
    required this.message,
    this.isError = false,
    this.progress,
    this.showIndeterminate = false,
    this.actions = const [],
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isError ? AppTheme.error : AppTheme.primary;
    final hasProgress = progress != null || showIndeterminate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.system_update_alt,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (hasProgress) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: showIndeterminate ? null : progress,
                    minHeight: 3,
                    color: accent,
                    backgroundColor: AppTheme.surface,
                  ),
                ],
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 8), action],
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 16),
              color: AppTheme.textSecondary,
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
