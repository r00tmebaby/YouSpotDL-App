import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

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
                  const Icon(
                    Icons.music_note,
                    size: 64,
                    color: AppTheme.primary,
                  ),
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
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionCard(
                  icon: Icons.download,
                  title: 'Download Playlist',
                  subtitle: 'Spotify or YouTube',
                  onTap: () => context.go('/download'),
                ),
                const SizedBox(width: 16),
                _ActionCard(
                  icon: Icons.list,
                  title: 'Download Queue',
                  subtitle: 'Manage downloads',
                  onTap: () => context.go('/queue'),
                ),
                const SizedBox(width: 16),
                _ActionCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'Past downloads',
                  onTap: () => context.go('/history'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Auth status
            if (!auth.isAuthenticated)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.warning),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Connect your Spotify account to download playlists.',
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
              ),
          ],
        ),
      ),
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
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
