import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import 'app_logo.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/download')) return 1;
    if (location.startsWith('/queue')) return 2;
    if (location.startsWith('/history')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  static const _destinations = [
    _NavDestination(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavDestination(icon: Icons.download_outlined, activeIcon: Icons.download, label: 'Download'),
    _NavDestination(icon: Icons.list_outlined, activeIcon: Icons.list, label: 'Queue'),
    _NavDestination(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
    _NavDestination(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: AppTheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Nav items
                ...List.generate(_destinations.length, (i) {
                  final dest = _destinations[i];
                  final selected = i == index;
                  return _NavItem(
                    icon: selected ? dest.activeIcon : dest.icon,
                    label: dest.label,
                    selected: selected,
                    onTap: () {
                      switch (i) {
                        case 0: context.go('/');
                        case 1: context.go('/download');
                        case 2: context.go('/queue');
                        case 3: context.go('/history');
                        case 4: context.go('/settings');
                      }
                    },
                  );
                }),

                const Spacer(),

                // Version + mini-logo at the very bottom
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      const AppLogo(size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(width: 1, color: AppTheme.surfaceVariant),

          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: widget.selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : _hovering
                  ? AppTheme.surfaceVariant
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.selected ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.selected ? AppTheme.primary : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
