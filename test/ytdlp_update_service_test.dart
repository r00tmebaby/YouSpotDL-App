import 'dart:ffi' show Abi;

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:youspotdl/services/ytdlp_update_service.dart';

void main() {
  group('assetName', () {
    test('windows uses the exe asset', () {
      expect(
        YtdlpUpdateService.assetName(
          isWindows: true,
          isMacOS: false,
          abi: Abi.windowsX64,
        ),
        'yt-dlp.exe',
      );
    });

    test('macos uses the macos asset', () {
      expect(
        YtdlpUpdateService.assetName(
          isWindows: false,
          isMacOS: true,
          abi: Abi.macosArm64,
        ),
        'yt-dlp_macos',
      );
    });

    test('linux x64 uses the standalone linux asset', () {
      expect(
        YtdlpUpdateService.assetName(
          isWindows: false,
          isMacOS: false,
          abi: Abi.linuxX64,
        ),
        'yt-dlp_linux',
      );
    });

    test('linux arm64 uses the aarch64 asset', () {
      expect(
        YtdlpUpdateService.assetName(
          isWindows: false,
          isMacOS: false,
          abi: Abi.linuxArm64,
        ),
        'yt-dlp_linux_aarch64',
      );
    });
  });

  group('managedPath', () {
    test('ends with yt-dlp.exe on Windows', () {
      final service = YtdlpUpdateService(
        toolsDir: r'C:\Users\me\AppData\Local\YouSpotDL\tools',
        isWindows: true,
        isMacOS: false,
        abi: Abi.windowsX64,
      );
      expect(p.basename(service.managedPath), 'yt-dlp.exe');
      expect(
        p.dirname(service.managedPath),
        r'C:\Users\me\AppData\Local\YouSpotDL\tools',
      );
    });

    test('is named yt-dlp on Linux', () {
      final service = YtdlpUpdateService(
        toolsDir: '/home/me/.local/share/tools',
        isWindows: false,
        isMacOS: false,
        abi: Abi.linuxX64,
      );
      expect(p.basename(service.managedPath), 'yt-dlp');
      expect(p.dirname(service.managedPath), '/home/me/.local/share/tools');
    });

    test('is named yt-dlp on macOS', () {
      final service = YtdlpUpdateService(
        toolsDir: '/Users/me/tools',
        isWindows: false,
        isMacOS: true,
        abi: Abi.macosArm64,
      );
      expect(p.basename(service.managedPath), 'yt-dlp');
    });
  });
}
