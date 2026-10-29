/// Unit tests for [ToolPaths] candidate ordering. Only pure functions are
/// exercised; directory resolution is not tested here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:youspotdl/services/tool_paths.dart';

void main() {
  group('names', () {
    test('managed yt-dlp name per platform', () {
      expect(ToolPaths.ytdlpManagedName(isWindows: true), 'yt-dlp.exe');
      expect(ToolPaths.ytdlpManagedName(isWindows: false), 'yt-dlp');
    });

    test('legacy yt-dlp names per platform, in order', () {
      expect(
        ToolPaths.legacyYtdlpNames(isWindows: true),
        ['dlp.exe', 'yt-dlp.exe'],
      );
      expect(
        ToolPaths.legacyYtdlpNames(isWindows: false),
        ['yt-dlp', 'dlp', 'yt-dlp.sh'],
      );
    });
  });

  group('ytdlpCandidates', () {
    test('windows without managed dir walks exeDir with legacy names', () {
      final result = ToolPaths.ytdlpCandidates(
        managedDir: null,
        exeDir: r'C:\a\b',
        isWindows: true,
      );
      expect(result, [
        r'C:\a\b\dlp.exe',
        r'C:\a\b\yt-dlp.exe',
        r'C:\a\dlp.exe',
        r'C:\a\yt-dlp.exe',
        r'C:\dlp.exe',
        r'C:\yt-dlp.exe',
      ]);
    });

    test('managed file comes first when managedDir is set', () {
      final result = ToolPaths.ytdlpCandidates(
        managedDir: r'C:\m\tools',
        exeDir: r'C:\a\b',
        isWindows: true,
        maxDepth: 1,
      );
      expect(result, [
        r'C:\m\tools\yt-dlp.exe',
        r'C:\a\b\dlp.exe',
        r'C:\a\b\yt-dlp.exe',
      ]);
    });

    test('posix ordering with managed dir', () {
      final result = ToolPaths.ytdlpCandidates(
        managedDir: '/m/tools',
        exeDir: '/a/b',
        isWindows: false,
        maxDepth: 2,
      );
      expect(result, [
        '/m/tools/yt-dlp',
        '/a/b/yt-dlp',
        '/a/b/dlp',
        '/a/b/yt-dlp.sh',
        '/a/yt-dlp',
        '/a/dlp',
        '/a/yt-dlp.sh',
      ]);
    });

    test('maxDepth limits the number of directories visited', () {
      final result = ToolPaths.ytdlpCandidates(
        managedDir: null,
        exeDir: '/a/b/c/d',
        isWindows: false,
        maxDepth: 2,
      );
      expect(result, [
        '/a/b/c/d/yt-dlp',
        '/a/b/c/d/dlp',
        '/a/b/c/d/yt-dlp.sh',
        '/a/b/c/yt-dlp',
        '/a/b/c/dlp',
        '/a/b/c/yt-dlp.sh',
      ]);
    });

    test('reaching root stops without looping', () {
      final result = ToolPaths.ytdlpCandidates(
        managedDir: null,
        exeDir: '/',
        isWindows: false,
        maxDepth: 50,
      );
      expect(result, ['/yt-dlp', '/dlp', '/yt-dlp.sh']);
    });
  });

  group('ffmpegCandidates', () {
    test('windows ordering with managed dir', () {
      final result = ToolPaths.ffmpegCandidates(
        managedDir: r'C:\m\tools',
        exeDir: r'C:\a\b',
        isWindows: true,
        maxDepth: 2,
      );
      expect(result, [
        r'C:\m\tools\ffmpeg\ffmpeg.exe',
        r'C:\m\tools\ffmpeg\bin\ffmpeg.exe',
        r'C:\a\b\ffmpeg.exe',
        r'C:\a\b\ffmpeg\ffmpeg.exe',
        r'C:\a\b\ffmpeg\bin\ffmpeg.exe',
        r'C:\a\ffmpeg.exe',
        r'C:\a\ffmpeg\ffmpeg.exe',
        r'C:\a\ffmpeg\bin\ffmpeg.exe',
      ]);
    });

    test('posix without managed dir, reaching root stops', () {
      final result = ToolPaths.ffmpegCandidates(
        managedDir: null,
        exeDir: '/',
        isWindows: false,
        maxDepth: 12,
      );
      expect(result, [
        '/ffmpeg',
        '/ffmpeg/ffmpeg',
        '/ffmpeg/bin/ffmpeg',
      ]);
    });

    test('default maxDepth of 12 limits deep walks', () {
      final result = ToolPaths.ffmpegCandidates(
        managedDir: null,
        exeDir: '/1/2/3/4/5/6/7/8/9/10/11/12/13/14',
        isWindows: false,
      );
      // 12 directories visited, 3 candidates each.
      expect(result.length, 36);
      expect(result.first, '/1/2/3/4/5/6/7/8/9/10/11/12/13/14/ffmpeg');
      // Walk starts at the deepest dir and stops after 12 dirs (14 down to 3).
      expect(result.last, '/1/2/3/ffmpeg/bin/ffmpeg');
    });
  });
}
