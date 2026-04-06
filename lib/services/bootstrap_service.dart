import 'dart:io';
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

  // yt-dlp's shared Windows build — ~96 MB compressed.
  // "Shared" means ffmpeg.exe + DLLs; all go into toolDir/ffmpeg/ so the
  // existing _findFfmpeg() path (toolDir/ffmpeg/ffmpeg.exe) finds it.
  static const _ffmpegZipUrl =
      'https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/'
      'ffmpeg-master-latest-win64-gpl-shared.zip';

  Stream<DownloadProgress> downloadFfmpeg() async* {
    if (!_isWin) {
      throw UnsupportedError(
        'Auto-download not available on ${Platform.operatingSystem}.\n'
        '${Platform.isMacOS ? "Run: brew install ffmpeg" : "Run: sudo apt install ffmpeg"}',
      );
    }

    final zipPath = pathlib.join(toolDir, '_ffmpeg_tmp.zip');

    // Step 1: download zip (0 → 85 %)
    await for (final p in _downloadFile(_ffmpegZipUrl, zipPath, 'Downloading ffmpeg')) {
      yield DownloadProgress(p.fraction * 0.85, p.label);
    }

    // Step 2: extract the bin/ folder from the zip into toolDir/ffmpeg/
    yield const DownloadProgress(0.87, 'Extracting ffmpeg…');

    final outDir = Directory(pathlib.join(toolDir, 'ffmpeg'));
    await outDir.create(recursive: true);

    // Use InputFileStream for memory-efficient extraction (avoids loading 96 MB at once).
    final inputStream = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(inputStream);
    int extracted = 0;

    for (final entry in archive) {
      if (!entry.isFile) continue;
      // Zip path: "ffmpeg-master-latest-win64-gpl-shared/bin/ffmpeg.exe"
      // → keep only the filename, write to toolDir/ffmpeg/filename
      final segments = entry.name.replaceAll('\\', '/').split('/');
      if (segments.length < 2) continue;
      final parent = segments[segments.length - 2]; // "bin"
      if (parent != 'bin') continue;

      final fileName = segments.last;
      final outPath = pathlib.join(outDir.path, fileName);
      final content = entry.content;
      if (content is List<int>) {
        File(outPath).writeAsBytesSync(content);
        extracted++;
      }
    }
    inputStream.closeSync();

    try { File(zipPath).deleteSync(); } catch (_) {}

    if (extracted == 0) throw Exception('No files extracted from ffmpeg zip.');
    yield const DownloadProgress(1.0, 'ffmpeg ready');
  }

  // ── Internal HTTP downloader ─────────────────────────────────────────────
  // Uses dart:io HttpClient so it follows 302 redirects automatically.
  // (GitHub releases always redirect to a CDN — http.Client.send() would fail.)

  Stream<DownloadProgress> _downloadFile(
    String url,
    String dest,
    String label,
  ) async* {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 10;

      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} while downloading $label');
      }

      final total = response.contentLength; // -1 if unknown
      var received = 0;

      await Directory(pathlib.dirname(dest)).create(recursive: true);
      final sink = File(dest).openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        final mb = (received / 1048576).toStringAsFixed(1);
        final totalMb = total > 0 ? ' / ${(total / 1048576).toStringAsFixed(1)} MB' : '';
        yield DownloadProgress(
          total > 0 ? received / total : (received / (30 * 1048576)).clamp(0.0, 0.99),
          '$label ($mb MB$totalMb)',
        );
      }
      await sink.close();
      yield DownloadProgress(1.0, '$label — done');
    } finally {
      httpClient.close(force: true);
    }
  }
}

