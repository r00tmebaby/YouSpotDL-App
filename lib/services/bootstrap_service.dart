import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as pathlib;

import 'download_service.dart';
import 'http_download.dart';
import 'ytdlp_update_service.dart';

export 'http_download.dart' show DownloadProgress;

// ── Data types ─────────────────────────────────────────────────────────────

class ToolStatus {
  final bool ytdlpFound;
  final bool ffmpegFound;

  const ToolStatus({required this.ytdlpFound, required this.ffmpegFound});

  bool get allReady => ytdlpFound && ffmpegFound;
}

// ── Service ────────────────────────────────────────────────────────────────

/// First-run setup and manual downloads of the external tools.
///
/// Everything is written to the user-writable [toolsDir], so setup and updates
/// work even when the app itself is installed in a read-only location such as
/// Program Files.
class BootstrapService {
  BootstrapService({required this.toolsDir, YtdlpUpdateService? ytdlp})
      : _ytdlp = ytdlp ?? YtdlpUpdateService(toolsDir: toolsDir);

  final String toolsDir;
  final YtdlpUpdateService _ytdlp;

  static bool get _isWin => Platform.isWindows;

  DownloadService get _lookup => DownloadService(managedToolsDir: toolsDir);

  bool get ytdlpAvailable => _lookup.isAvailable;

  bool get ffmpegAvailable => _lookup.ffmpegAvailable;

  ToolStatus checkStatus() => ToolStatus(
        ytdlpFound: ytdlpAvailable,
        ffmpegFound: ffmpegAvailable,
      );

  /// Whether ffmpeg can be auto-downloaded (Windows only).
  /// macOS/Linux users have brew/apt.
  bool get canAutoDownloadFfmpeg => _isWin;

  // ── yt-dlp download ───────────────────────────────────────────────────────

  /// Installs the latest yt-dlp into the tools directory. Shares its code
  /// path with the automatic updater.
  Stream<DownloadProgress> downloadYtdlp() => _ytdlp.install();

  // ── ffmpeg download (Windows only) ───────────────────────────────────────

  // yt-dlp's shared Windows build, about 96 MB compressed. "Shared" means
  // ffmpeg.exe plus DLLs; all of bin/ goes into <toolsDir>/ffmpeg/.
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

    final zipPath = pathlib.join(toolsDir, '_ffmpeg_tmp.zip');

    // Step 1: download zip (0 → 85 %)
    await for (final p in downloadToFile(_ffmpegZipUrl, zipPath, 'Downloading ffmpeg')) {
      yield DownloadProgress(p.fraction * 0.85, p.label);
    }

    // Step 2: extract the bin/ folder from the zip into toolsDir/ffmpeg/
    yield const DownloadProgress(0.87, 'Extracting ffmpeg…');

    final outDir = Directory(pathlib.join(toolsDir, 'ffmpeg'));
    await outDir.create(recursive: true);

    // InputFileStream keeps memory flat instead of loading 96 MB at once.
    final inputStream = InputFileStream(zipPath);
    var extracted = 0;
    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      for (final entry in archive) {
        if (!entry.isFile) continue;
        // Zip path: "ffmpeg-master-latest-win64-gpl-shared/bin/ffmpeg.exe"
        final segments = entry.name.replaceAll('\\', '/').split('/');
        if (segments.length < 2 || segments[segments.length - 2] != 'bin') {
          continue;
        }
        File(pathlib.join(outDir.path, segments.last))
            .writeAsBytesSync(entry.content);
        extracted++;
      }
    } finally {
      inputStream.closeSync();
      try {
        File(zipPath).deleteSync();
      } catch (_) {}
    }

    if (extracted == 0) throw Exception('No files extracted from ffmpeg zip.');
    yield const DownloadProgress(1.0, 'ffmpeg ready');
  }

  /// Re-downloads ffmpeg even if already present (Windows only).
  Stream<DownloadProgress> updateFfmpeg() => downloadFfmpeg();
}
