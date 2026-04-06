import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/video_info.dart';

class DownloadService {
  String? _ytdlpPath;
  String? _ffmpegPath;

  // ── Platform helpers ────────────────────────────────────────────────────
  static bool get _isWindows => Platform.isWindows;
  static String get _whichCmd => _isWindows ? 'where' : 'which';

  /// Find yt-dlp executable — cross-platform (Windows / macOS / Linux).
  String _findYtdlp() {
    if (_ytdlpPath != null && File(_ytdlpPath!).existsSync()) return _ytdlpPath!;

    // Candidate binary names in priority order
    final names = _isWindows
        ? ['dlp.exe', 'yt-dlp.exe']
        : ['yt-dlp', 'dlp', 'yt-dlp.sh'];

    final exeDir = p.dirname(Platform.resolvedExecutable);

    // Walk up the directory tree (covers dev layout and installed app)
    var dir = exeDir;
    for (var i = 0; i < 10; i++) {
      for (final name in names) {
        final candidate = p.join(dir, name);
        if (File(candidate).existsSync()) {
          _ytdlpPath = candidate;
          return _ytdlpPath!;
        }
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }

    // Fallback: system PATH
    for (final name in (_isWindows ? ['dlp', 'yt-dlp'] : ['yt-dlp', 'dlp'])) {
      try {
        final r = Process.runSync(_whichCmd, [name], stdoutEncoding: utf8, stderrEncoding: utf8);
        if (r.exitCode == 0) {
          final path = (r.stdout as String).trim().split('\n').first.trim();
          if (path.isNotEmpty && File(path).existsSync()) {
            _ytdlpPath = path;
            return _ytdlpPath!;
          }
        }
      } catch (_) {}
    }

    throw Exception(
      'yt-dlp not found.\n'
      '• Windows : place dlp.exe or yt-dlp.exe next to the app\n'
      '• macOS   : brew install yt-dlp  OR  pip install yt-dlp\n'
      '• Linux   : pip install yt-dlp   OR  sudo apt install yt-dlp',
    );
  }

  /// Find ffmpeg location directory — cross-platform (Windows / macOS / Linux).
  String? _findFfmpeg() {
    final binName = _isWindows ? 'ffmpeg.exe' : 'ffmpeg';

    if (_ffmpegPath != null && File(p.join(_ffmpegPath!, binName)).existsSync()) {
      return _ffmpegPath!;
    }

    final exeDir = p.dirname(Platform.resolvedExecutable);

    var dir = exeDir;
    for (var i = 0; i < 12; i++) {
      for (final candidate in [
        p.join(dir, binName),
        p.join(dir, 'ffmpeg', binName),
        p.join(dir, 'ffmpeg', 'bin', binName),
      ]) {
        if (File(candidate).existsSync()) {
          _ffmpegPath = p.dirname(candidate);
          return _ffmpegPath!;
        }
      }

      // Recursively walk any 'ffmpeg' subfolder (handles versioned zip extraction)
      final ffmpegSubdir = Directory(p.join(dir, 'ffmpeg'));
      if (ffmpegSubdir.existsSync()) {
        try {
          for (final entity in ffmpegSubdir.listSync(recursive: true)) {
            if (entity is File && p.basename(entity.path).toLowerCase() == binName) {
              _ffmpegPath = p.dirname(entity.path);
              return _ffmpegPath!;
            }
          }
        } catch (_) {}
      }

      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }

    // Last resort: system PATH (works for brew/apt installs on macOS/Linux)
    try {
      final result = Process.runSync(_whichCmd, ['ffmpeg'], stdoutEncoding: utf8, stderrEncoding: utf8);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim().split('\n').first.trim();
        if (path.isNotEmpty && File(path).existsSync()) {
          _ffmpegPath = p.dirname(path);
          return _ffmpegPath!;
        }
      }
    } catch (_) {}

    return null;
  }

  bool get isAvailable {
    try { _findYtdlp(); return true; } catch (_) { return false; }
  }

  bool get ffmpegAvailable => _findFfmpeg() != null;

  /// Returns the full path to the yt-dlp binary being used, or null.
  String? getYtdlpPath() {
    try { return _findYtdlp(); } catch (_) { return null; }
  }

  /// Returns the full path to the ffmpeg binary being used, or null.
  String? getFfmpegPath() {
    final dir = _findFfmpeg();
    if (dir == null) return null;
    return p.join(dir, _isWindows ? 'ffmpeg.exe' : 'ffmpeg');
  }

  /// Returns the installed yt-dlp version string, e.g. "2024.11.18".
  Future<String?> getYtdlpVersion() async {
    try {
      final r = await Process.run(_findYtdlp(), ['--version'], stdoutEncoding: utf8, stderrEncoding: utf8);
      if (r.exitCode == 0) return (r.stdout as String).trim();
    } catch (_) {}
    return null;
  }

  /// Returns the installed ffmpeg version string (first token after "version").
  Future<String?> getFfmpegVersion() async {
    try {
      final dir = _findFfmpeg();
      if (dir == null) return null;
      final bin = p.join(dir, _isWindows ? 'ffmpeg.exe' : 'ffmpeg');
      final r = await Process.run(bin, ['-version'], stdoutEncoding: utf8, stderrEncoding: utf8);
      if (r.exitCode == 0) {
        final first = (r.stdout as String).split('\n').first;
        final m = RegExp(r'version\s+(\S+)').firstMatch(first);
        return m?.group(1) ?? first;
      }
    } catch (_) {}
    return null;
  }

  /// Check if a song file already exists in the output directory.
  /// Uses word-overlap matching against the song title (before " - artist").
  String? findExistingFile(String outputDir, String query) {
    final dir = Directory(outputDir);
    if (!dir.existsSync()) return null;

    // Normalize: lowercase, strip non-alphanumeric, collapse whitespace
    String normalize(String text) => text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Meaningful words only (length > 2)
    List<String> words(String text) =>
        normalize(text).split(' ').where((w) => w.length > 2).toList();

    // Only compare against the song title part (before " - Artist")
    final titlePart = query.split(' - ').first;
    final queryWords = words(titlePart);
    if (queryWords.isEmpty) return null;

    final audioExts = {'.mp3', '.m4a', '.opus', '.webm', '.ogg', '.flac'};

    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      if (!audioExts.contains(p.extension(entity.path).toLowerCase())) continue;

      final fileWords = words(p.basenameWithoutExtension(entity.path));
      if (fileWords.isEmpty) continue;

      final matches = queryWords.where((w) => fileWords.contains(w)).length;
      // 60%+ of title words found in filename → consider it a match
      if (matches / queryWords.length >= 0.6) return entity.path;
    }
    return null;
  }

  /// Fetch a Spotify playlist's tracks via yt-dlp — works for **public** playlists
  /// without any Spotify API credentials. Returns a map with keys `playlistName`
  /// (String) and `tracks` (List<Map<String,String>> with `title` and `artist`),
  /// or `null` when yt-dlp cannot access the playlist (private, bad URL, or old
  /// yt-dlp build that lacks Spotify support).
  Future<Map<String, dynamic>?> fetchSpotifyPlaylistViaYtdlp(String url) async {
    try {
      final ytdlp = _findYtdlp();
      final result = await Process.run(
        ytdlp,
        ['--flat-playlist', '--print', '%(playlist_title)s|%(title)s|%(artist)s', url],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 60));

      if (result.exitCode != 0) return null;

      final output = result.stdout as String;
      if (output.trim().isEmpty) return null;

      String? playlistName;
      final tracks = <Map<String, String>>[];

      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final idx1 = trimmed.indexOf('|');
        if (idx1 < 0) continue;
        final idx2 = trimmed.indexOf('|', idx1 + 1);
        if (idx2 < 0) continue;

        final plTitle = trimmed.substring(0, idx1).trim();
        final title   = trimmed.substring(idx1 + 1, idx2).trim();
        final artist  = trimmed.substring(idx2 + 1).trim();

        if (playlistName == null && plTitle.isNotEmpty && plTitle != 'NA') {
          playlistName = plTitle;
        }
        if (title.isNotEmpty && title != 'NA') {
          tracks.add({
            'title':  title,
            'artist': (artist.isEmpty || artist == 'NA') ? 'Unknown' : artist,
          });
        }
      }

      if (tracks.isEmpty) return null;
      return {
        'playlistName': playlistName ?? 'Spotify Playlist',
        'tracks': tracks,
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetch video titles and URLs from a YouTube playlist.
  Future<List<Map<String, String>>> fetchYouTubePlaylist(String url) async {
    final ytdlp = _findYtdlp();
    final result = await Process.run(
      ytdlp,
      ['--flat-playlist', '--print', '%(title)s|%(url)s', url],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    final entries = <Map<String, String>>[];
    for (final line in result.stdout.split('\n')) {
      final idx = line.indexOf('|');
      if (idx < 1) continue;
      final title = line.substring(0, idx).trim();
      final videoUrl = line.substring(idx + 1).trim();
      if (title.isNotEmpty && videoUrl.isNotEmpty) {
        entries.add({'title': title, 'url': videoUrl});
      }
    }
    return entries;
  }

  /// Download a single song, streaming progress events.
  /// [query]        – either a search string ("Song - Artist") or a direct URL.
  /// [displayTitle] – used for existing-file matching when query is a URL.
  Stream<SongDownloadProgress> downloadSong({
    required String query,
    required String outputDir,
    required int index,
    String? displayTitle,
  }) async* {
    final ytdlp = _findYtdlp();
    final ffmpeg = _findFfmpeg();

    final isUrl = query.startsWith('http://') || query.startsWith('https://');
    // For existing-file check use the display title when available, otherwise the query
    final checkName = displayTitle ?? (isUrl ? '' : query);

    // Check if already downloaded
    final existing = checkName.isNotEmpty ? findExistingFile(outputDir, checkName) : null;
    if (existing != null) {
      yield SongDownloadProgress(
        index: index,
        status: SongDownloadStatus.skipped,
        query: query,
        percent: 100,
        filePath: existing,
      );
      return;
    }

    yield SongDownloadProgress(index: index, status: SongDownloadStatus.starting, query: query);

    // Direct URL → pass as-is; search string → use ytsearch:
    final target = isUrl ? query : 'ytsearch:$query';

    final args = <String>[
      '-x',
      '--audio-format', 'mp3',
      '--audio-quality', '0',
      '--newline',
      '--no-playlist',
      '--no-warnings',
      '--no-overwrites',
      if (ffmpeg != null) ...['--ffmpeg-location', ffmpeg],
      '--output', p.join(outputDir, '%(title)s.%(ext)s'),
      '--concurrent-fragments', '8',   // parallel HTTP fragments — big speed boost
      '--buffer-size', '16K',           // larger read buffer → fewer syscalls
      '--retries', '3',
      '--progress-template', '%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s',
      target,
    ];


    final process = await Process.start(ytdlp, args);

    // Drain stderr concurrently — prevents pipe-buffer deadlock when ffmpeg outputs heavily
    final stderrFuture = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.trim())
        .toList();

    var wasSkipped = false;

    await for (final line
        in process.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Detect yt-dlp's "already downloaded / skipping" messages
      if (trimmed.contains('has already been downloaded') ||
          trimmed.contains('Skipping, file already exists') ||
          (trimmed.startsWith('[download]') && trimmed.contains('already'))) {
        wasSkipped = true;
        continue;
      }

      final parts = trimmed.split('|');
      if (parts.length == 3) {
        try {
          final percent = double.parse(parts[0].replaceAll('%', '').trim());
          yield SongDownloadProgress(
            index: index,
            status: SongDownloadStatus.downloading,
            query: query,
            percent: percent,
            speed: parts[1].trim(),
            eta: parts[2].trim(),
          );
          continue;
        } catch (_) {}
      }

      if (trimmed.contains('[ExtractAudio]') || trimmed.contains('Deleting original')) {
        yield SongDownloadProgress(
          index: index,
          status: SongDownloadStatus.extracting,
          query: query,
          percent: 100,
        );
      }
    }

    final stderrLines = await stderrFuture;
    final exitCode = await process.exitCode;

    if (exitCode == 0 || wasSkipped) {
      // Try to find the downloaded file
      String? downloadedFile;
      if (wasSkipped) {
        downloadedFile = existing;
      } else {
        final outputDirEntity = Directory(outputDir);
        if (outputDirEntity.existsSync()) {
          final files = outputDirEntity.listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.mp3'))
              .toList();
          if (files.isNotEmpty) {
            files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
            downloadedFile = files.first.path;
          }
        }
      }

      yield SongDownloadProgress(
        index: index,
        status: wasSkipped ? SongDownloadStatus.skipped : SongDownloadStatus.completed,
        query: query,
        percent: 100,
        filePath: downloadedFile,
      );
    } else {
      final errorMsg = stderrLines.isNotEmpty
          ? stderrLines.last
          : 'Download failed (exit code $exitCode)';
      yield SongDownloadProgress(
        index: index,
        status: SongDownloadStatus.error,
        query: query,
        error: errorMsg,
      );
    }
  }

  /// Fetch video metadata for a single YouTube video URL.
  Future<VideoInfo> fetchVideoInfo(String url) async {
    final ytdlp = _findYtdlp();
    final result = await Process.run(
      ytdlp,
      ['--dump-json', '--no-playlist', url],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      throw Exception('Failed to fetch video info: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout) as Map<String, dynamic>;
    return VideoInfo.fromJson(json, url);
  }

  /// Download a single video with a chosen format, streaming progress events.
  Stream<SongDownloadProgress> downloadVideo({
    required String url,
    required String outputDir,
    required String formatSelector,
    required String outputExt,
    required bool audioOnly,
    required int index,
  }) async* {
    final ytdlp = _findYtdlp();
    final ffmpeg = _findFfmpeg();

    // MP3/audio conversion requires ffmpeg — fail fast with a clear message
    if (audioOnly && ffmpeg == null) {
      yield SongDownloadProgress(
        index: index,
        status: SongDownloadStatus.error,
        query: url,
        error: 'ffmpeg is required for MP3 conversion but was not found.\n'
               'Place ffmpeg.zip in the project folder and restart the app.',
      );
      return;
    }

    yield SongDownloadProgress(index: index, status: SongDownloadStatus.starting, query: url);

    final args = <String>[
      '-f', formatSelector,
      '--newline',
      '--no-playlist',
      if (ffmpeg != null) ...['--ffmpeg-location', ffmpeg],
      '--output', p.join(outputDir, '%(title)s.%(ext)s'),
      '--concurrent-fragments', '8',
      '--buffer-size', '16K',
      '--retries', '3',
      '--progress-template', '%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s',
    ];

    if (audioOnly) {
      args.addAll(['-x', '--audio-format', outputExt, '--audio-quality', '0']);
    } else {
      args.addAll(['--merge-output-format', outputExt]);
    }

    args.add(url);

    final process = await Process.start(ytdlp, args);

    // Drain stderr concurrently — prevents pipe-buffer deadlock when ffmpeg outputs heavily
    final stderrFuture = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.trim())
        .toList();

    // Stream stdout for progress
    await for (final line
        in process.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split('|');
      if (parts.length == 3) {
        try {
          final percent = double.parse(parts[0].replaceAll('%', '').trim());
          yield SongDownloadProgress(
            index: index,
            status: SongDownloadStatus.downloading,
            query: url,
            percent: percent,
            speed: parts[1].trim(),
            eta: parts[2].trim(),
          );
          continue;
        } catch (_) {}
      }

      if (trimmed.contains('[ExtractAudio]') || trimmed.contains('Deleting original') ||
          trimmed.contains('[Merger]') || trimmed.contains('Merging')) {
        yield SongDownloadProgress(
          index: index,
          status: SongDownloadStatus.extracting,
          query: url,
          percent: 100,
        );
      }
    }

    final stderrLines = await stderrFuture;
    final exitCode = await process.exitCode;

    if (exitCode == 0) {
      // Try to find the downloaded file
      final outputDirEntity = Directory(outputDir);
      String? downloadedFile;
      if (outputDirEntity.existsSync()) {
        final files = outputDirEntity.listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.$outputExt') || f.path.endsWith('.mp4') || f.path.endsWith('.mp3'))
            .toList();
        if (files.isNotEmpty) {
          // Sort by modification time, get most recent
          files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          downloadedFile = files.first.path;
        }
      }

      yield SongDownloadProgress(
        index: index,
        status: SongDownloadStatus.completed,
        query: url,
        percent: 100,
        filePath: downloadedFile,
      );
    } else {
      yield SongDownloadProgress(
        index: index,
        status: SongDownloadStatus.error,
        query: url,
        error: _extractErrorMessage(stderrLines, exitCode),
      );
    }
  }

  /// Pick the most relevant error line from yt-dlp/ffmpeg stderr output.
  String _extractErrorMessage(List<String> lines, int exitCode) {
    // Prefer explicit ERROR lines
    for (final line in lines.reversed) {
      final l = line.toLowerCase();
      if (l.startsWith('error') || l.contains('[error]') || l.contains('error:')) {
        return line;
      }
    }
    // Fallback: last non-empty, non-ffmpeg-codec-listing line
    for (final line in lines.reversed) {
      if (!line.startsWith(' ') && line.isNotEmpty) return line;
    }
    return lines.isNotEmpty ? lines.last : 'Download failed (exit code $exitCode)';
  }
}

enum SongDownloadStatus { starting, downloading, extracting, completed, error, skipped }

class SongDownloadProgress {
  final int index;
  final SongDownloadStatus status;
  final String query;
  final double percent;
  final String speed;
  final String eta;
  final String? error;
  final String? filePath;

  const SongDownloadProgress({
    required this.index,
    required this.status,
    required this.query,
    this.percent = 0,
    this.speed = '',
    this.eta = '',
    this.error,
    this.filePath,
  });
}
