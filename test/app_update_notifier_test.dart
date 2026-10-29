import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youspotdl/models/download_task.dart' show DownloadStatus;
import 'package:youspotdl/providers/update_provider.dart';
import 'package:youspotdl/services/app_update_service.dart';
import 'package:youspotdl/services/update_prefs.dart';

const _releasePage = 'https://github.com/r00tmebaby/YouSpotDL-App/releases/tag/v99.0.0';

/// Answers the GitHub "latest release" call with a release far ahead of the
/// running version that carries the asset for the host platform.
http.Client _gitHubStub() => MockClient((request) async {
      return http.Response(
        jsonEncode({
          'tag_name': 'v99.0.0',
          'html_url': _releasePage,
          'body': '',
          'assets': [
            {
              'name': AppUpdateService.platformAssetName(),
              'browser_download_url': 'https://example.invalid/asset',
              'size': 1024,
            },
          ],
        }),
        200,
      );
    });

void main() {
  late Directory supportDir;
  late UpdatePrefs prefs;
  late List<int> exitCodes;
  late List<Uri> openedUrls;

  setUp(() async {
    supportDir = await Directory.systemTemp.createTemp('youspotdl_notifier_');
    SharedPreferences.setMockInitialValues({});
    prefs = UpdatePrefs(await SharedPreferences.getInstance());
    exitCodes = [];
    openedUrls = [];
  });

  tearDown(() async {
    if (supportDir.existsSync()) await supportDir.delete(recursive: true);
  });

  Future<AppUpdateNotifier> availableNotifier({
    required bool inPlace,
    required bool activeDownloads,
  }) async {
    final service = AppUpdateService(
      appSupportDir: supportDir.path,
      client: _gitHubStub(),
      supportsInPlaceUpdate: inPlace,
    );
    final notifier = AppUpdateNotifier(
      service,
      prefs,
      exitApp: exitCodes.add,
      hasActiveDownloads: () => activeDownloads,
      openUrl: (url) async {
        openedUrls.add(url);
        return true;
      },
    );
    await notifier.check(manual: true);
    expect(notifier.state.phase, AppUpdatePhase.available);
    return notifier;
  }

  group('startUpdate', () {
    test('refuses to download or exit while downloads are active', () async {
      final notifier = await availableNotifier(inPlace: true, activeDownloads: true);

      await notifier.startUpdate();

      expect(notifier.state.phase, AppUpdatePhase.failed);
      expect(notifier.state.message, AppUpdateNotifier.activeDownloadsMessage);
      expect(notifier.state.release?.version, '99.0.0');
      expect(exitCodes, isEmpty);
      expect(Directory('${supportDir.path}/updates').existsSync(), isFalse);
      expect(prefs.applyingTag, isNull);
    });

    test('opens the release page where in-place updates are unsupported', () async {
      final notifier = await availableNotifier(inPlace: false, activeDownloads: false);

      await notifier.startUpdate();

      expect(openedUrls, [Uri.parse(_releasePage)]);
      expect(notifier.state.phase, AppUpdatePhase.available);
      expect(notifier.supportsInPlaceUpdate, isFalse);
      expect(exitCodes, isEmpty);
      expect(Directory('${supportDir.path}/updates').existsSync(), isFalse);
    });
  });

  group('isActiveDownloadStatus', () {
    test('treats only finished tasks as inactive', () {
      expect(isActiveDownloadStatus(DownloadStatus.pending), isTrue);
      expect(isActiveDownloadStatus(DownloadStatus.fetching), isTrue);
      expect(isActiveDownloadStatus(DownloadStatus.downloading), isTrue);
      expect(isActiveDownloadStatus(DownloadStatus.completed), isFalse);
      expect(isActiveDownloadStatus(DownloadStatus.error), isFalse);
    });
  });
}
