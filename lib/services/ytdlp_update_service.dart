import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/version_utils.dart';
import 'http_download.dart';
import 'tool_paths.dart';

/// Keeps the managed yt-dlp binary in the tools directory current.
///
/// The latest version is read from the redirect target of the GitHub
/// "latest release" page, which costs no API quota. A new binary is only put
/// in place after it has been downloaded completely and `--version` succeeds,
/// so a failed update never replaces a working binary.
class YtdlpUpdateService {
  YtdlpUpdateService({
    required this.toolsDir,
    bool? isWindows,
    bool? isMacOS,
    Abi? abi,
  })  : _isWindows = isWindows ?? Platform.isWindows,
        _isMacOS = isMacOS ?? Platform.isMacOS,
        _abi = abi ?? Abi.current();

  static const _latestReleaseUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest';
  static const _downloadBaseUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/';

  final String toolsDir;
  final bool _isWindows;
  final bool _isMacOS;
  final Abi _abi;

  /// Path of the managed binary, whether or not it exists yet.
  String get managedPath =>
      p.join(toolsDir, ToolPaths.ytdlpManagedName(isWindows: _isWindows));

  /// Release asset for the current platform. The Linux builds are standalone
  /// executables; the plain `yt-dlp` asset would require a system Python.
  static String assetName({
    required bool isWindows,
    required bool isMacOS,
    required Abi abi,
  }) {
    if (isWindows) return 'yt-dlp.exe';
    if (isMacOS) return 'yt-dlp_macos';
    if (abi == Abi.linuxArm64) return 'yt-dlp_linux_aarch64';
    return 'yt-dlp_linux';
  }

  /// Returns the tag of the latest yt-dlp release, for example "2026.10.26".
  Future<String> latestVersion() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = httpUserAgent;
    try {
      final request = await client
          .headUrl(Uri.parse(_latestReleaseUrl))
          .timeout(const Duration(seconds: 15));
      request.followRedirects = false;
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      await response.drain<void>();
      final tag =
          tagFromLocation(response.headers.value(HttpHeaders.locationHeader));
      if (tag == null) {
        throw HttpException(
          'No release tag in the redirect (HTTP ${response.statusCode})',
          uri: Uri.parse(_latestReleaseUrl),
        );
      }
      return tag;
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads the latest yt-dlp and swaps it in as the managed binary.
  Stream<DownloadProgress> install() async* {
    await Directory(toolsDir).create(recursive: true);
    _deleteLeftovers();

    final target = managedPath;
    final temp = '$target.download';
    final url =
        '$_downloadBaseUrl${assetName(isWindows: _isWindows, isMacOS: _isMacOS, abi: _abi)}';

    yield* downloadToFile(url, temp, 'Downloading yt-dlp');

    try {
      if (!_isWindows) {
        final chmod = await Process.run('chmod', ['755', temp]);
        if (chmod.exitCode != 0) {
          throw ProcessException('chmod', ['755', temp], '${chmod.stderr}');
        }
      }
      yield const DownloadProgress(1.0, 'Verifying yt-dlp');
      final check = await Process.run(
        temp,
        ['--version'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 90));
      if (check.exitCode != 0) {
        throw ProcessException(
          temp,
          ['--version'],
          'The downloaded yt-dlp did not start: ${check.stderr}',
          check.exitCode,
        );
      }
      await _swapIn(temp, target);
      yield DownloadProgress(
        1.0,
        'yt-dlp ${(check.stdout as String).trim()} installed',
      );
    } catch (_) {
      _tryDelete(temp);
      rethrow;
    }
  }

  /// Moves [temp] to [target] without ever leaving [target] missing or broken.
  ///
  /// POSIX rename replaces the file atomically, even while the old binary is
  /// running. Windows refuses to overwrite an executable that is in use but
  /// allows renaming it, so the old file is moved aside first and moved back
  /// if the second rename fails.
  Future<void> _swapIn(String temp, String target) async {
    if (!_isWindows) {
      await File(temp).rename(target);
      return;
    }
    final current = File(target);
    String? aside;
    if (current.existsSync()) {
      aside = '$target.old-${DateTime.now().millisecondsSinceEpoch}';
      await current.rename(aside);
    }
    try {
      await File(temp).rename(target);
    } catch (_) {
      if (aside != null) await File(aside).rename(target);
      rethrow;
    }
    if (aside != null) _tryDelete(aside);
  }

  /// Removes old binaries and partial downloads from earlier runs. Files that
  /// are still locked by a running yt-dlp are left for the next attempt.
  void _deleteLeftovers() {
    final base = p.basename(managedPath);
    try {
      for (final entity in Directory(toolsDir).listSync()) {
        final name = p.basename(entity.path);
        if (entity is File &&
            (name.startsWith('$base.old-') || name == '$base.download')) {
          _tryDelete(entity.path);
        }
      }
    } catch (_) {}
  }

  static void _tryDelete(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }
}
