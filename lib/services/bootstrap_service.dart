import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as pathlib;
import 'package:archive/archive_io.dart';

// ── Data types ─────────────────────────────────────────────────────────────

class ToolStatus {
  final bool ytdlpFound;
  final bool ffmpegFound;

  const ToolStatus({required this.ytdlpFound, required this.ffmpegFound});

  bool get allReady => ytdlpFound && ffmpegFound;
}

class DownloadProgress {
  final double fraction; // 0.0 → 1.0
  final String label;    // e.g. "Downloading yt-dlp…"

  const DownloadProgress(this.fraction, this.label);
}

// ── Service ────────────────────────────────────────────────────────────────

class BootstrapService {
  static bool get _isWin => Platform.isWindows;

  // ── Tool directory ────────────────────────────────────────────────────────
  /// Returns the directory where tools should be downloaded.
  /// In dev mode walks up to find project root (pubspec.yaml).
  /// In release mode uses the exe directory.
  static String get toolDir {
    final exeDir = pathlib.dirname(Platform.resolvedExecutable);
    var dir = exeDir;
    for (var i = 0; i < 10; i++) {
      if (File(pathlib.join(dir, 'pubspec.yaml')).existsSync()) return dir;
      final parent = pathlib.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
    return exeDir;
  }

  // ── Status checks ─────────────────────────────────────────────────────────

  static bool get ytdlpAvailable {
    final names = _isWin ? ['dlp.exe', 'yt-dlp.exe'] : ['yt-dlp', 'dlp'];
    for (final name in names) {
      if (File(pathlib.join(toolDir, name)).existsSync()) return true;
    }
    final whichCmd = _isWin ? 'where' : 'which';
    for (final name in ['yt-dlp', 'dlp']) {
      try {
        if (Process.runSync(whichCmd, [name]).exitCode == 0) return true;
      } catch (_) {}
    }
    return false;
  }

  static bool get ffmpegAvailable {
    final bin = _isWin ? 'ffmpeg.exe' : 'ffmpeg';
    final dir = toolDir;
    for (final candidate in [
      pathlib.join(dir, bin),
      pathlib.join(dir, 'ffmpeg', bin),
      pathlib.join(dir, 'ffmpeg', 'bin', bin),
    ]) {
      if (File(candidate).existsSync()) return true;
    }
    try {
      if (Process.runSync(_isWin ? 'where' : 'which', ['ffmpeg']).exitCode == 0) return true;
    } catch (_) {}
    return false;
  }

  static ToolStatus checkStatus() => ToolStatus(
        ytdlpFound: ytdlpAvailable,
        ffmpegFound: ffmpegAvailable,
      );

  /// Whether ffmpeg can be auto-downloaded (Windows only).
  /// macOS/Linux users have brew/apt.
  bool get canAutoDownloadFfmpeg => _isWin;

  // ── yt-dlp download ───────────────────────────────────────────────────────

  static String get _ytdlpUrl {
    if (_isWin) return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
    if (Platform.isMacOS) return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos';
    return 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp';
  }

  Stream<DownloadProgress> downloadYtdlp() async* {
    final dest = pathlib.join(toolDir, _isWin ? 'yt-dlp.exe' : 'yt-dlp');
    yield* _downloadFile(_ytdlpUrl, dest, 'Downloading yt-dlp');
    if (!_isWin) {
      await Process.run('chmod', ['+x', dest]);
    }
  }

  // ── ffmpeg download (Windows only) ───────────────────────────────────────

  // yt-dlp's own essentials build — contains only ffmpeg/ffprobe (~25 MB)
  static const _ffmpegZipUrl =
      'https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/'
      'ffmpeg-master-latest-win64-gpl-essentials.zip';

  Stream<DownloadProgress> downloadFfmpeg() async* {
    if (!_isWin) {
      throw UnsupportedError(
        'Auto-download not available on ${Platform.operatingSystem}.\n'
        '${Platform.isMacOS ? "Run: brew install ffmpeg" : "Run: sudo apt install ffmpeg"}',
      );
    }

    final zipPath = pathlib.join(toolDir, '_ffmpeg_tmp.zip');

    // Download (reports 0→85%)
    await for (final p in _downloadFile(_ffmpegZipUrl, zipPath, 'Downloading ffmpeg')) {
      yield DownloadProgress(p.fraction * 0.85, p.label);
    }

    // Extract ffmpeg.exe from the zip (85→100%)
    yield const DownloadProgress(0.87, 'Extracting ffmpeg.exe…');
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    bool extracted = false;
    for (final entry in archive) {
      if (entry.isFile && pathlib.basename(entry.name).toLowerCase() == 'ffmpeg.exe') {
        final outPath = pathlib.join(toolDir, 'ffmpeg.exe');
        File(outPath).writeAsBytesSync(entry.content as List<int>);
        extracted = true;
        break;
      }
    }

    try { File(zipPath).deleteSync(); } catch (_) {}

    if (!extracted) throw Exception('ffmpeg.exe not found inside the downloaded zip.');
    yield const DownloadProgress(1.0, 'ffmpeg ready');
  }

  // ── Internal HTTP downloader ──────────────────────────────────────────────

  Stream<DownloadProgress> _downloadFile(
    String url,
    String dest,
    String label,
  ) async* {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url));
      final resp = await client.send(req);
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode} while downloading $label');
      }

      final total = resp.contentLength ?? 0;
      var received = 0;

      await Directory(pathlib.dirname(dest)).create(recursive: true);
      final sink = File(dest).openWrite();

      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        yield DownloadProgress(
          total > 0 ? received / total : 0,
          '$label${total > 0 ? ' (${(received / 1048576).toStringAsFixed(1)} / ${(total / 1048576).toStringAsFixed(1)} MB)' : '…'}',
        );
      }
      await sink.close();
      yield DownloadProgress(1.0, '$label — done');
    } finally {
      client.close();
    }
  }
}

