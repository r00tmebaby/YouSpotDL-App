/// Locations and lookup order for external tools (yt-dlp, ffmpeg).
///
/// Candidate lists are built by pure functions so they can be tested
/// independently of the host OS. Path joining uses a [p.Context] whose style
/// follows the `isWindows` flag rather than the running platform.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolves tool file paths in lookup order.
class ToolPaths {
  ToolPaths._();

  /// Name of the managed yt-dlp executable for the given platform.
  static String ytdlpManagedName({required bool isWindows}) =>
      isWindows ? 'yt-dlp.exe' : 'yt-dlp';

  /// Legacy yt-dlp file names searched next to the executable, in order.
  static List<String> legacyYtdlpNames({required bool isWindows}) => isWindows
      ? const ['dlp.exe', 'yt-dlp.exe']
      : const ['yt-dlp', 'dlp', 'yt-dlp.sh'];

  /// Ordered yt-dlp candidate paths.
  ///
  /// The managed file comes first when [managedDir] is non-null. Then each
  /// directory from [exeDir] upward is checked for every legacy name.
  static List<String> ytdlpCandidates({
    required String? managedDir,
    required String exeDir,
    required bool isWindows,
    int maxDepth = 10,
  }) {
    final ctx = _context(isWindows);
    final names = legacyYtdlpNames(isWindows: isWindows);
    final result = <String>[];

    if (managedDir != null) {
      result.add(
        ctx.join(managedDir, ytdlpManagedName(isWindows: isWindows)),
      );
    }

    for (final dir in _walkUp(ctx, exeDir, maxDepth)) {
      for (final name in names) {
        result.add(ctx.join(dir, name));
      }
    }
    return result;
  }

  /// Ordered ffmpeg candidate paths.
  ///
  /// Managed locations under `<managedDir>/ffmpeg` come first, then each
  /// directory from [exeDir] upward is checked in the order `<d>/<bin>`,
  /// `<d>/ffmpeg/<bin>`, `<d>/ffmpeg/bin/<bin>`.
  static List<String> ffmpegCandidates({
    required String? managedDir,
    required String exeDir,
    required bool isWindows,
    int maxDepth = 12,
  }) {
    final ctx = _context(isWindows);
    final bin = isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    final result = <String>[];

    if (managedDir != null) {
      result.add(ctx.join(managedDir, 'ffmpeg', bin));
      result.add(ctx.join(managedDir, 'ffmpeg', 'bin', bin));
    }

    for (final dir in _walkUp(ctx, exeDir, maxDepth)) {
      result.add(ctx.join(dir, bin));
      result.add(ctx.join(dir, 'ffmpeg', bin));
      result.add(ctx.join(dir, 'ffmpeg', 'bin', bin));
    }
    return result;
  }

  /// Returns the managed tools directory, creating it if needed.
  ///
  /// The directory is `tools` inside the application support directory.
  static Future<String> resolveToolsDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'tools'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static p.Context _context(bool isWindows) =>
      p.Context(style: isWindows ? p.Style.windows : p.Style.posix);

  /// Lists [start] and its ancestors, stopping at the root or after
  /// [maxDepth] directories.
  static List<String> _walkUp(p.Context ctx, String start, int maxDepth) {
    final dirs = <String>[];
    var current = start;
    for (var i = 0; i < maxDepth; i++) {
      dirs.add(current);
      final parent = ctx.dirname(current);
      // dirname of a root returns the root itself.
      if (parent == current) break;
      current = parent;
    }
    return dirs;
  }
}
