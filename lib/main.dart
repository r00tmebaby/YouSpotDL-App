import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';

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

  final container = ProviderContainer();
  await container.read(settingsProvider.notifier).load();
  await container.read(authProvider.notifier).loadSavedTokens();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const YouSpotDLApp(),
  ));
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
