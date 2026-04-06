import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/download_page.dart';
import '../pages/queue_page.dart';
import '../pages/history_page.dart';
import '../pages/settings_page.dart';
import '../widgets/app_shell.dart';

final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/download',
          builder: (context, state) => const DownloadPage(),
        ),
        GoRoute(
          path: '/queue',
          builder: (context, state) => const QueuePage(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
