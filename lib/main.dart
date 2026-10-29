import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/update_provider.dart';
import 'services/tool_paths.dart';
import 'services/update_prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window setup
  try {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setSize(const Size(1100, 700));
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.setTitle('YouSpotDL');
      await windowManager.show();
    });
  } catch (_) {
    // Not a desktop platform, ignore
  }

  final container = ProviderContainer(
    overrides: [
      toolsDirProvider.overrideWithValue(await _resolveToolsDir()),
      updatePrefsProvider.overrideWithValue(await UpdatePrefs.load()),
    ],
  );
  await container.read(settingsProvider.notifier).load();
  await container.read(authProvider.notifier).loadSavedTokens();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const YouSpotDLApp(),
  ));

  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(_runStartupUpdates(container)),
  );
}

/// The managed tools directory, or a folder next to the executable when the
/// platform reports no application support directory.
Future<String> _resolveToolsDir() async {
  try {
    return await ToolPaths.resolveToolsDir();
  } catch (_) {
    return p.join(p.dirname(Platform.resolvedExecutable), 'tools');
  }
}

/// Background update work after the first frame. Every step reports through
/// its provider state and never blocks or crashes the UI.
Future<void> _runStartupUpdates(ProviderContainer container) async {
  final app = container.read(appUpdateProvider.notifier);
  try {
    container.read(previousUpdateResultProvider.notifier).state =
        await app.consumePreviousResult();
  } catch (_) {}
  try {
    await container.read(ytdlpUpdaterProvider.notifier).checkAndUpdate();
  } catch (_) {}
  try {
    await app.check();
  } catch (_) {}
}

class YouSpotDLApp extends StatelessWidget {
  const YouSpotDLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YouSpotDL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
