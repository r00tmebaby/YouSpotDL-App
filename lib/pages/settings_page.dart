import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../providers/update_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _clientIdCtrl;
  late TextEditingController _clientSecretCtrl;
  late TextEditingController _redirectUriCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _clientIdCtrl = TextEditingController(text: s.clientId);
    _clientSecretCtrl = TextEditingController(text: s.clientSecret);
    _redirectUriCtrl = TextEditingController(text: s.redirectUri);
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _redirectUriCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsProvider.notifier).save(
          ref.read(settingsProvider).copyWith(
                clientId: _clientIdCtrl.text.trim(),
                clientSecret: _clientSecretCtrl.text.trim(),
                redirectUri: _redirectUriCtrl.text.trim(),
              ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Spotify credentials section
          const _SectionHeader(title: 'Spotify API Credentials', icon: Icons.key),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 15, color: AppTheme.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Optional — public Spotify playlists are downloaded automatically without any credentials. '
                    'Only needed if you want to access your private or collaborative playlists.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Client ID',
              hintText: 'From Spotify Developer Dashboard',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _clientSecretCtrl,
            decoration: const InputDecoration(
              labelText: 'Client Secret',
              hintText: 'From Spotify Developer Dashboard',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _redirectUriCtrl,
            decoration: const InputDecoration(
              labelText: 'Redirect URI',
              hintText: defaultRedirectUri,
            ),
          ),
          const SizedBox(height: 16),

          // Spotify connection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    auth.isAuthenticated ? Icons.verified : Icons.link_off,
                    color: auth.isAuthenticated ? AppTheme.success : AppTheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isAuthenticated ? 'Connected to Spotify' : 'Not connected',
                          style: TextStyle(
                            color: auth.isAuthenticated ? AppTheme.success : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          auth.isAuthenticated
                              ? 'Your Spotify account is linked'
                              : 'Save credentials first, then connect',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (auth.isAuthenticated)
                    TextButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      child: const Text('Disconnect'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () async {
                        await _save();
                        if (!context.mounted) return;
                        if (_clientIdCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter Client ID first')),
                          );
                          return;
                        }
                        ref.read(authProvider.notifier).login(
                              clientId: _clientIdCtrl.text.trim(),
                              clientSecret: _clientSecretCtrl.text.trim(),
                              redirectUri: _redirectUriCtrl.text.trim(),
                            );
                      },
                      child: const Text('Connect'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (auth.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            )),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(auth.error!, style: const TextStyle(color: AppTheme.error)),
            ),

          const SizedBox(height: 32),

          // Download settings
          const _SectionHeader(title: 'Downloads', icon: Icons.folder),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Download Location'),
            subtitle: Text(
              settings.downloadDir.isEmpty ? 'Not set (ask each time)' : settings.downloadDir,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.folder_open, color: AppTheme.primary),
            onTap: () async {
              final picked = await FilePicker.platform.getDirectoryPath(
                dialogTitle: 'Select default download folder',
              );
              if (picked != null) {
                await ref.read(settingsProvider.notifier).save(
                      settings.copyWith(downloadDir: picked),
                    );
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Concurrent Downloads'),
              const Spacer(),
              Text(
                '${settings.concurrency}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: settings.concurrency.toDouble(),
            min: minConcurrency.toDouble(),
            max: maxConcurrency.toDouble(),
            divisions: maxConcurrency - minConcurrency,
            onChanged: (v) => ref.read(settingsProvider.notifier).save(
              settings.copyWith(concurrency: v.round()),
            ),
          ),
          const SizedBox(height: 32),

          // ── System Tools ─────────────────────────────────────────────────
          const _SectionHeader(title: 'System Tools', icon: Icons.build_outlined),
          const SizedBox(height: 12),
          _ToolsInfoCard(),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Tools status card ──────────────────────────────────────────────────────
class _ToolsInfoCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(toolsInfoProvider);
    final ytdlpUpdate = ref.watch(ytdlpUpdaterProvider);
    final os = Platform.operatingSystem; // 'windows' | 'macos' | 'linux'
    final osBadge = {'windows': '🪟 Windows', 'macos': '🍎 macOS', 'linux': '🐧 Linux'}[os] ?? os;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform row
            Row(
              children: [
                const Icon(Icons.computer, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text('Platform: $osBadge',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            toolsAsync.when(
              loading: () => const Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Detecting tools…', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
              error: (_, _) => const Text('Could not detect tools',
                  style: TextStyle(color: AppTheme.error, fontSize: 13)),
              data: (tools) {
                final ytVer  = tools['ytdlp'];
                final ffVer  = tools['ffmpeg'];
                final ytPath = tools['ytdlp_path'];
                final ffPath = tools['ffmpeg_path'];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ToolRow(
                      icon: Icons.download_for_offline_outlined,
                      name: 'yt-dlp',
                      version: ytVer,
                      path: ytPath,
                      hint: ytVer == null
                          ? (os == 'windows'
                              ? 'Use the Update yt-dlp button below to install it'
                              : 'Use the Update yt-dlp button below or run: pip install yt-dlp')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _ToolRow(
                      icon: Icons.movie_filter_outlined,
                      name: 'ffmpeg',
                      version: ffVer,
                      path: ffPath,
                      hint: ffVer == null
                          ? (os == 'windows'
                              ? 'Extract ffmpeg.zip next to the app'
                              : os == 'macos'
                                  ? 'Run: brew install ffmpeg'
                                  : 'Run: sudo apt install ffmpeg')
                          : null,
                      warningIfMissing: 'MP3 conversion and HD video merging will not work',
                    ),
                    // Add update buttons for yt-dlp and ffmpeg
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.system_update_alt),
                            label: const Text('Update yt-dlp'),
                            onPressed: ytdlpUpdate.isBusy
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final updater = ref.read(ytdlpUpdaterProvider.notifier);
                                    await updater.checkAndUpdate(force: true);
                                    ref.invalidate(toolsInfoProvider);
                                    final message = ref.read(ytdlpUpdaterProvider).message;
                                    if (message != null) {
                                      messenger.showSnackBar(SnackBar(content: Text(message)));
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (Platform.isWindows)
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.system_update_alt),
                              label: const Text('Update ffmpeg'),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => const Center(child: CircularProgressIndicator()),
                                );
                                try {
                                  await ref.read(bootstrapServiceProvider).updateFfmpeg().drain<void>();
                                  ref.read(downloadServiceProvider).resetToolCache();
                                  messenger.showSnackBar(const SnackBar(content: Text('ffmpeg updated')));
                                  ref
                                    ..invalidate(toolsInfoProvider)
                                    ..invalidate(toolStatusProvider);
                                } catch (e) {
                                  messenger.showSnackBar(SnackBar(content: Text('ffmpeg update failed: $e')));
                                } finally {
                                  if (context.mounted) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                    if (ytdlpUpdate.phase == YtdlpUpdatePhase.downloading) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: ytdlpUpdate.fraction, minHeight: 3),
                    ],
                    if (ytdlpUpdate.isBusy && ytdlpUpdate.message != null) ...[
                      const SizedBox(height: 6),
                      Text(ytdlpUpdate.message!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const _AppVersionRow(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the running app version, the latest known release and the manual
/// update controls.
class _AppVersionRow extends ConsumerWidget {
  const _AppVersionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);
    final latest = state.release?.version;
    final showMessage = state.message != null &&
        (state.phase == AppUpdatePhase.upToDate || state.phase == AppUpdatePhase.failed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            const Text('App version',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(width: 8),
            _VersionBadge(text: 'v$appVersion', color: AppTheme.success),
            if (latest != null && latest != appVersion) ...[
              const SizedBox(width: 8),
              _VersionBadge(text: 'latest v$latest', color: AppTheme.primary),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton(
              onPressed: state.isBusy ? null : () => notifier.check(manual: true),
              child: const Text('Check for updates'),
            ),
            if (state.phase == AppUpdatePhase.available) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: notifier.startUpdate,
                child: Text(notifier.supportsInPlaceUpdate
                    ? 'Update now'
                    : 'Open release page'),
              ),
            ],
            if (state.phase == AppUpdatePhase.checking) ...[
              const SizedBox(width: 12),
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
        if (state.phase == AppUpdatePhase.available &&
            !notifier.supportsInPlaceUpdate) ...[
          const SizedBox(height: 6),
          const Text(
              'On this platform the new version is installed manually '
              'from the release page.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
        if (showMessage) ...[
          const SizedBox(height: 6),
          Text(state.message!,
              style: TextStyle(
                color: state.phase == AppUpdatePhase.failed
                    ? AppTheme.error
                    : AppTheme.textSecondary,
                fontSize: 11,
              )),
        ],
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _VersionBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String? version;
  final String? path;
  final String? hint;
  final String? warningIfMissing;

  const _ToolRow({
    required this.icon,
    required this.name,
    this.version,
    this.path,
    this.hint,
    this.warningIfMissing,
  });

  @override
  Widget build(BuildContext context) {
    final found = version != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: found ? AppTheme.success : AppTheme.error),
            const SizedBox(width: 8),
            Text(name,
                style: TextStyle(
                  color: found ? AppTheme.textPrimary : AppTheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(width: 8),
            if (found)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('v$version',
                    style: const TextStyle(color: AppTheme.success, fontSize: 11)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('not found',
                    style: TextStyle(color: AppTheme.error, fontSize: 11)),
              ),
          ],
        ),
        // ── Show resolved path so user can confirm which binary is used ──
        if (found && path != null) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: SelectableText(
              path!,
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
        if (!found && hint != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(hint!,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ),
        ],
        if (!found && warningIfMissing != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text('⚠ $warningIfMissing',
                style: const TextStyle(color: AppTheme.warning, fontSize: 11)),
          ),
        ],
      ],
    );
  }
}
