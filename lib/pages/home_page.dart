import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../services/bootstrap_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final toolStatus = ref.watch(toolStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Center(
              child: Column(
                children: [
                  const Icon(Icons.music_note, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to YouSpotDL',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Download Spotify & YouTube playlists with ease',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Quick actions
            Text('Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionCard(icon: Icons.download, title: 'Download Playlist', subtitle: 'Spotify or YouTube', onTap: () => context.go('/download')),
                const SizedBox(width: 16),
                _ActionCard(icon: Icons.list, title: 'Download Queue', subtitle: 'Manage downloads', onTap: () => context.go('/queue')),
                const SizedBox(width: 16),
                _ActionCard(icon: Icons.history, title: 'History', subtitle: 'Past downloads', onTap: () => context.go('/history')),
              ],
            ),
            const SizedBox(height: 24),

            // ── Setup banner (shown when tools are missing) ───────────────
            toolStatus.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (status) => status.allReady
                  ? const SizedBox.shrink()
                  : _SetupBanner(
                      status: status,
                      onSetup: () async {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => _SetupDialog(ref: ref),
                        );
                        ref.invalidate(toolStatusProvider);
                        ref.invalidate(downloadServiceProvider);
                        ref.invalidate(toolsInfoProvider);
                      },
                    ),
            ),

            // Spotify auth notice (only when tools are ready)
            toolStatus.maybeWhen(
              data: (s) => s.allReady && !auth.isAuthenticated
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.warning),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Connect your Spotify account to access private playlists.',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/settings'),
                              child: const Text('Set up'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Setup banner ────────────────────────────────────────────────────────────

class _SetupBanner extends StatelessWidget {
  final ToolStatus status;
  final VoidCallback onSetup;

  const _SetupBanner({required this.status, required this.onSetup});

  @override
  Widget build(BuildContext context) {
    final missing = [
      if (!status.ytdlpFound) 'yt-dlp',
      if (!status.ffmpegFound) 'ffmpeg',
    ];

    return Card(
      color: AppTheme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.build_outlined, color: AppTheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Required tools not found',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    'Missing: ${missing.join(", ")}. '
                    '${Platform.isWindows ? "Click Auto-Setup to download them automatically." : "Install via your package manager."}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Auto-Setup'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Setup dialog ────────────────────────────────────────────────────────────

class _SetupDialog extends StatefulWidget {
  final WidgetRef ref;
  const _SetupDialog({required this.ref});

  @override
  State<_SetupDialog> createState() => _SetupDialogState();
}

class _SetupDialogState extends State<_SetupDialog> {
  final _svc = BootstrapService();

  double _ytProgress = -1; // -1 = not started, 0..1 = in progress, 2 = done, -2 = error
  double _ffProgress = -1;
  String _ytLabel = '';
  String _ffLabel = '';
  String? _ytError;
  String? _ffError;
  bool _running = false;
  bool get _done =>
      (_ytProgress == 2 || _ytProgress == -2 || _ytProgress == -1 && BootstrapService.ytdlpAvailable) &&
      (_ffProgress == 2 || _ffProgress == -2 || _ffProgress == -1 && BootstrapService.ffmpegAvailable);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _running = true);
    final futures = <Future>[];

    if (!BootstrapService.ytdlpAvailable) {
      futures.add(_runYtdlp());
    } else {
      setState(() { _ytProgress = 2; _ytLabel = 'Already installed'; });
    }

    if (!BootstrapService.ffmpegAvailable) {
      if (_svc.canAutoDownloadFfmpeg) {
        futures.add(_runFfmpeg());
      } else {
        setState(() {
          _ffProgress = -2;
          _ffError = Platform.isMacOS ? 'brew install ffmpeg' : 'sudo apt install ffmpeg';
        });
      }
    } else {
      setState(() { _ffProgress = 2; _ffLabel = 'Already installed'; });
    }

    await Future.wait(futures);
    setState(() => _running = false);
  }

  Future<void> _runYtdlp() async {
    setState(() { _ytProgress = 0; _ytLabel = 'Starting…'; });
    try {
      await for (final p in _svc.downloadYtdlp()) {
        if (!mounted) return;
        setState(() { _ytProgress = p.fraction; _ytLabel = p.label; });
      }
      if (mounted) setState(() { _ytProgress = 2; _ytLabel = 'yt-dlp installed ✓'; });
    } catch (e) {
      if (mounted) setState(() { _ytProgress = -2; _ytError = e.toString(); });
    }
  }

  Future<void> _runFfmpeg() async {
    setState(() { _ffProgress = 0; _ffLabel = 'Starting…'; });
    try {
      await for (final p in _svc.downloadFfmpeg()) {
        if (!mounted) return;
        setState(() { _ffProgress = p.fraction; _ffLabel = p.label; });
      }
      if (mounted) setState(() { _ffProgress = 2; _ffLabel = 'ffmpeg installed ✓'; });
    } catch (e) {
      if (mounted) setState(() { _ffProgress = -2; _ffError = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.build_outlined, color: AppTheme.primary),
        SizedBox(width: 10),
        Text('First-Time Setup'),
      ]),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Downloading required tools next to the app. This only happens once.\n'
              'yt-dlp ~10 MB · ffmpeg ~96 MB (Windows shared build)',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _ToolProgressTile(
              name: 'yt-dlp',
              icon: Icons.download_for_offline_outlined,
              progress: _ytProgress,
              label: _ytLabel,
              error: _ytError,
            ),
            const SizedBox(height: 14),
            _ToolProgressTile(
              name: 'ffmpeg',
              icon: Icons.movie_filter_outlined,
              progress: _ffProgress,
              label: _ffLabel,
              error: _ffError,
            ),
          ],
        ),
      ),
      actions: [
        if (_done)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          )
        else if (_running)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

class _ToolProgressTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final double progress; // -1 not started, 0..1 progress, 2 done, -2 error
  final String label;
  final String? error;

  const _ToolProgressTile({
    required this.name,
    required this.icon,
    required this.progress,
    required this.label,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isDone   = progress == 2;
    final isError  = progress == -2;
    final isNotStarted = progress == -1;
    final isActive = !isDone && !isError && !isNotStarted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDone ? AppTheme.success : isError ? AppTheme.error : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Text(name,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(width: 8),
            if (isDone)
              const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 16)
            else if (isError)
              const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          ],
        ),
        const SizedBox(height: 6),
        if (isActive) ...[
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ] else if (isError) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              error ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.error, fontSize: 11),
            ),
          ),
        ] else ...[
          Text(label,
              style: TextStyle(
                color: isDone ? AppTheme.success : AppTheme.textSecondary,
                fontSize: 11,
              )),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppTheme.primary, size: 32),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
