/// Unit tests for [AppUpdateService] and [ReleaseInfo] parsing, install path
/// resolution and zip extraction. No network access is used.
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:youspotdl/services/app_update_service.dart';

const _assetName = 'YouSpotDL-windows.zip';

Map<String, dynamic> _releaseJson({
  String tag = 'v1.0.2',
  List<Map<String, dynamic>>? assets,
}) {
  return {
    'tag_name': tag,
    'html_url': 'https://github.com/r00tmebaby/YouSpotDL-App/releases/tag/$tag',
    'body': 'Fixes playlist fetch.',
    'assets': assets ??
        [
          {
            'name': _assetName,
            'browser_download_url': 'https://example.test/$_assetName',
            'size': 1234,
          },
        ],
  };
}

void main() {
  group('ReleaseInfo.fromGitHubJson', () {
    test('parses a release with a matching asset', () {
      final info = ReleaseInfo.fromGitHubJson(_releaseJson(), _assetName);

      expect(info, isNotNull);
      expect(info!.version, '1.0.2');
      expect(info.tag, 'v1.0.2');
      expect(info.htmlUrl, 'https://github.com/r00tmebaby/YouSpotDL-App/releases/tag/v1.0.2');
      expect(info.notes, 'Fixes playlist fetch.');
      expect(info.assetName, _assetName);
      expect(info.assetUrl, 'https://example.test/$_assetName');
      expect(info.assetSize, 1234);
    });

    test('returns null when no asset matches the platform name', () {
      final json = _releaseJson(assets: [
        {
          'name': 'YouSpotDL-linux.tar.gz',
          'browser_download_url': 'https://example.test/linux.tar.gz',
          'size': 99,
        },
      ]);

      expect(ReleaseInfo.fromGitHubJson(json, _assetName), isNull);
    });

    test('returns null when the matching asset size is not positive', () {
      for (final size in [0, -5, '1234']) {
        final json = _releaseJson(assets: [
          {
            'name': _assetName,
            'browser_download_url': 'https://example.test/$_assetName',
            'size': size,
          },
        ]);

        expect(ReleaseInfo.fromGitHubJson(json, _assetName), isNull, reason: 'size $size');
      }
    });

    test('returns null when the tag is missing or empty', () {
      expect(ReleaseInfo.fromGitHubJson(_releaseJson(tag: ''), _assetName), isNull);

      final noTag = _releaseJson()..remove('tag_name');
      expect(ReleaseInfo.fromGitHubJson(noTag, _assetName), isNull);
    });
  });

  group('ReleaseInfo JSON round trip', () {
    const release = ReleaseInfo(
      version: '1.0.2',
      tag: 'v1.0.2',
      htmlUrl: 'https://example.test/release',
      notes: 'Line one\nLine two',
      assetName: _assetName,
      assetUrl: 'https://example.test/asset.zip',
      assetSize: 4096,
    );

    test('tryFromJson restores every field written by toJson', () {
      final restored = ReleaseInfo.tryFromJson(jsonEncode(release.toJson()));

      expect(restored, isNotNull);
      expect(restored!.version, release.version);
      expect(restored.tag, release.tag);
      expect(restored.htmlUrl, release.htmlUrl);
      expect(restored.notes, release.notes);
      expect(restored.assetName, release.assetName);
      expect(restored.assetUrl, release.assetUrl);
      expect(restored.assetSize, release.assetSize);
    });

    test('tryFromJson returns null for null input', () {
      expect(ReleaseInfo.tryFromJson(null), isNull);
    });

    test('tryFromJson returns null for garbage input', () {
      expect(ReleaseInfo.tryFromJson('not json at all'), isNull);
      expect(ReleaseInfo.tryFromJson('[1, 2, 3]'), isNull);
      expect(ReleaseInfo.tryFromJson('{"version": "1.0.2"}'), isNull);
      expect(ReleaseInfo.tryFromJson(''), isNull);
    });
  });

  group('AppUpdateService.installPath', () {
    test('windows returns the folder holding the executable', () {
      final exe = p.join('C:', 'Apps', 'YouSpotDL', 'YouSpotDL.exe');

      expect(
        AppUpdateService.installPath(exe, isMacOS: false),
        p.join('C:', 'Apps', 'YouSpotDL'),
      );
    });

    test('macos returns the .app bundle around Contents/MacOS', () {
      final exe = p.join('/Applications', 'YouSpotDL.app', 'Contents', 'MacOS', 'YouSpotDL');

      expect(
        AppUpdateService.installPath(exe, isMacOS: true),
        p.join('/Applications', 'YouSpotDL.app'),
      );
    });

    test('macos falls back to the executable folder outside a bundle', () {
      final exe = p.join('/opt', 'youspotdl', 'bin', 'YouSpotDL');

      expect(
        AppUpdateService.installPath(exe, isMacOS: true),
        p.join('/opt', 'youspotdl', 'bin'),
      );
    });
  });

  group('AppUpdateService.extractZip', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('app_update_zip_test_');
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    String writeZip(String name, List<ArchiveFile> files) {
      final archive = Archive();
      for (final file in files) {
        archive.addFile(file);
      }
      final bytes = ZipEncoder().encode(archive);
      final path = p.join(tempRoot.path, name);
      File(path).writeAsBytesSync(bytes);
      return path;
    }

    test('writes nested files under the destination', () {
      final zip = writeZip('ok.zip', [
        ArchiveFile.string('YouSpotDL.exe', 'binary'),
        ArchiveFile.string('data/flutter_assets/config.json', '{"a":1}'),
      ]);
      final destination = p.join(tempRoot.path, 'out');
      Directory(destination).createSync();

      AppUpdateService.extractZip(zip, destination);

      expect(File(p.join(destination, 'YouSpotDL.exe')).readAsStringSync(), 'binary');
      expect(
        File(p.join(destination, 'data', 'flutter_assets', 'config.json')).readAsStringSync(),
        '{"a":1}',
      );
    });

    test('throws and writes nothing outside the destination for a traversal entry', () {
      final zip = writeZip('evil.zip', [
        ArchiveFile.string('../evil.txt', 'escape'),
      ]);
      final destination = p.join(tempRoot.path, 'out');
      Directory(destination).createSync();

      expect(
        () => AppUpdateService.extractZip(zip, destination),
        throwsA(isA<FileSystemException>()),
      );
      expect(File(p.join(tempRoot.path, 'evil.txt')).existsSync(), isFalse);
    });
  });
}
