import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../core/version_utils.dart';
import 'http_download.dart';
import 'update_helper_script.dart';

/// A published app release and the asset that fits the current platform.
class ReleaseInfo {
  final String version;
  final String tag;
  final String htmlUrl;
  final String notes;
  final String assetName;
  final String assetUrl;
  final int assetSize;

  const ReleaseInfo({
    required this.version,
    required this.tag,
    required this.htmlUrl,
    required this.notes,
    required this.assetName,
    required this.assetUrl,
    required this.assetSize,
  });

  /// Parses a GitHub "latest release" API response. Returns null when the
  /// release has no asset named [assetName], so a partially uploaded release
  /// is never offered.
  static ReleaseInfo? fromGitHubJson(Map<String, dynamic> json, String assetName) {
    final tag = json['tag_name'];
    if (tag is! String || tag.isEmpty) return null;
    final assets = json['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is Map<String, dynamic> && asset['name'] == assetName) {
        final url = asset['browser_download_url'];
        final size = asset['size'];
        if (url is! String || size is! int || size <= 0) return null;
        return ReleaseInfo(
          version: normalizeVersion(tag),
          tag: tag,
          htmlUrl: json['html_url'] is String
              ? json['html_url'] as String
              : AppUpdateService.releasesPage,
          notes: json['body'] is String ? json['body'] as String : '',
          assetName: assetName,
          assetUrl: url,
          assetSize: size,
        );
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'tag': tag,
        'htmlUrl': htmlUrl,
        'notes': notes,
        'assetName': assetName,
        'assetUrl': assetUrl,
        'assetSize': assetSize,
      };

  static ReleaseInfo? tryFromJson(String? source) {
    if (source == null) return null;
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      return ReleaseInfo(
        version: json['version'] as String,
        tag: json['tag'] as String,
        htmlUrl: json['htmlUrl'] as String,
        notes: json['notes'] as String,
        assetName: json['assetName'] as String,
        assetUrl: json['assetUrl'] as String,
        assetSize: json['assetSize'] as int,
      );
    } catch (_) {
      return null;
    }
  }
}

/// How handing the staged update to the helper ended.
enum ApplyOutcome {
  /// The helper is running; the app must exit now so it can replace files.
  launched,

  /// Administrator rights were required and the UAC prompt was declined.
  elevationDeclined,

  /// The install location is not writable and cannot be elevated here.
  notWritable,
}

/// Downloads, stages and applies app releases from GitHub.
///
/// All work happens below `<app support>/updates/<tag>/`; the tools directory,
/// the history file and preferences are never touched.
class AppUpdateService {
  AppUpdateService({
    required this.appSupportDir,
    http.Client? client,
    String? resolvedExecutable,
    bool? supportsInPlaceUpdate,
  })  : _client = client ?? http.Client(),
        _executable = resolvedExecutable ?? Platform.resolvedExecutable,
        supportsInPlaceUpdate = supportsInPlaceUpdate ?? Platform.isWindows;

  static const repository = 'r00tmebaby/YouSpotDL-App';
  static const releasesPage = 'https://github.com/$repository/releases/latest';
  static const _latestApi =
      'https://api.github.com/repos/$repository/releases/latest';

  final String appSupportDir;

  /// Whether this platform replaces the installed files from inside the app.
  /// Only Windows does for now: the macOS and Linux helpers stay in place but
  /// those platforms send the user to the release page until they are proven.
  final bool supportsInPlaceUpdate;

  final http.Client _client;
  final String _executable;

  String get updatesDir => p.join(appSupportDir, 'updates');

  String workDir(String tag) => p.join(updatesDir, tag);

  String logPath(String tag) => p.join(workDir(tag), 'update.log');

  /// Release asset produced by .github/workflows/build.yml for this platform.
  static String? platformAssetName() {
    if (Platform.isWindows) return 'YouSpotDL-windows.zip';
    if (Platform.isMacOS) return 'YouSpotDL-macos.tar.gz';
    if (Platform.isLinux) return 'YouSpotDL-linux.tar.gz';
    return null;
  }

  /// The directory replaced by an update: the folder holding the executable,
  /// or on macOS the `.app` bundle around `Contents/MacOS/<exe>`.
  static String installPath(String executable, {required bool isMacOS}) {
    final exeDir = p.dirname(executable);
    if (!isMacOS) return exeDir;
    final bundle = p.dirname(p.dirname(exeDir));
    return bundle.endsWith('.app') ? bundle : exeDir;
  }

  String get _installPath => installPath(_executable, isMacOS: Platform.isMacOS);

  /// Queries the GitHub API for the latest release. Returns null when the
  /// release has no asset for this platform.
  Future<ReleaseInfo?> fetchLatestRelease() async {
    final assetName = platformAssetName();
    if (assetName == null) return null;
    final response = await _client.get(
      Uri.parse(_latestApi),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': httpUserAgent,
      },
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'GitHub returned HTTP ${response.statusCode}',
        uri: Uri.parse(_latestApi),
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ReleaseInfo.fromGitHubJson(json, assetName);
  }

  /// Downloads the release asset and checks its size against the API value.
  /// Yields progress; the archive ends up at [archivePath].
  Stream<DownloadProgress> download(ReleaseInfo release) async* {
    final dir = Directory(workDir(release.tag));
    if (dir.existsSync()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final target = archivePath(release);
    final temp = '$target.download';
    yield* downloadToFile(release.assetUrl, temp, 'Downloading YouSpotDL ${release.version}');

    final size = await File(temp).length();
    if (size != release.assetSize) {
      await File(temp).delete();
      throw HttpException(
        'Downloaded $size bytes but the release lists ${release.assetSize}',
        uri: Uri.parse(release.assetUrl),
      );
    }
    await File(temp).rename(target);
  }

  String archivePath(ReleaseInfo release) =>
      p.join(workDir(release.tag), release.assetName);

  /// Extracts the downloaded archive into `staged/` and checks that it holds
  /// the same executable as the running app. Returns the path to copy from:
  /// the staged folder, or on macOS the staged `.app` bundle.
  Future<String> stage(ReleaseInfo release) async {
    final staged = p.join(workDir(release.tag), 'staged');
    final stagedDir = Directory(staged);
    if (stagedDir.existsSync()) await stagedDir.delete(recursive: true);
    await stagedDir.create(recursive: true);

    final archive = archivePath(release);
    if (Platform.isWindows) {
      extractZip(archive, staged);
    } else {
      // System tar keeps symlinks and permission bits, which the bundle needs.
      final result = await Process.run('tar', ['-xzf', archive, '-C', staged]);
      if (result.exitCode != 0) {
        throw ProcessException('tar', ['-xzf', archive], '${result.stderr}', result.exitCode);
      }
    }

    final exeName = p.basename(_executable);
    final String source;
    final String expected;
    if (Platform.isMacOS) {
      source = p.join(staged, p.basename(_installPath));
      expected = p.join(source, 'Contents', 'MacOS', exeName);
    } else {
      source = staged;
      expected = p.join(staged, exeName);
    }
    if (!File(expected).existsSync()) {
      throw FileSystemException('The release archive does not contain $exeName', archive);
    }
    // Installing a binary without any execute bit would leave an app that
    // cannot start, so such an archive is rejected before anything is swapped.
    if (!Platform.isWindows && File(expected).statSync().mode & 0x49 == 0) {
      throw FileSystemException('$exeName in the release archive is not executable', archive);
    }
    return source;
  }

  /// Extracts a zip archive into [destination], refusing entries that would
  /// land outside it.
  static void extractZip(String zipPath, String destination) {
    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final root = p.normalize(p.absolute(destination));
      for (final entry in archive) {
        final name = entry.name.replaceAll('\\', '/');
        final target = p.normalize(p.join(root, name));
        if (p.isAbsolute(name) || !p.isWithin(root, target)) {
          throw FileSystemException('Unsafe path in update archive', entry.name);
        }
        if (entry.isFile) {
          File(target)
            ..createSync(recursive: true)
            ..writeAsBytesSync(entry.content);
        } else {
          Directory(target).createSync(recursive: true);
        }
      }
    } finally {
      input.closeSync();
    }
  }

  /// Whether [dir] accepts new files without elevation.
  static bool isWritable(String dir) {
    final probe = File(p.join(dir, '.youspotdl_write_probe'));
    try {
      probe.writeAsStringSync('');
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Writes the helper script and starts it. On [ApplyOutcome.launched] the
  /// caller must exit the app so the helper can replace the files.
  Future<ApplyOutcome> apply(ReleaseInfo release, String stagedPath) async {
    final install = _installPath;
    final work = workDir(release.tag);
    final params = HelperScriptParams(
      pid: pid,
      stagedPath: stagedPath,
      installPath: install,
      backupPath: p.join(work, 'backup', Platform.isMacOS ? p.basename(install) : ''),
      logPath: logPath(release.tag),
      relaunchPath: Platform.isMacOS ? install : _executable,
    );
    // The macOS helper renames the bundle, which needs its parent to be writable.
    final writable = isWritable(install) &&
        (!Platform.isMacOS || isWritable(p.dirname(install)));

    if (Platform.isWindows) {
      final script = p.join(work, 'apply_update.ps1');
      // Windows PowerShell reads BOM-less scripts in the ANSI code page, which
      // would corrupt non-ASCII profile paths.
      await File(script).writeAsBytes(
        [0xEF, 0xBB, 0xBF, ...utf8.encode(UpdateHelperScript.windows(params))],
      );
      // A read-only install folder (Program Files) needs the helper elevated.
      final launcher = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-EncodedCommand',
        UpdateHelperScript.encodePowerShellCommand(
          UpdateHelperScript.windowsLauncher(script, elevated: !writable),
        ),
      ]);
      if (launcher.exitCode == 0) return ApplyOutcome.launched;
      if (!writable) return ApplyOutcome.elevationDeclined;
      throw ProcessException(
        'powershell.exe',
        const ['-EncodedCommand'],
        'The update helper could not be started: ${launcher.stderr}',
        launcher.exitCode,
      );
    }

    if (!writable) return ApplyOutcome.notWritable;
    final script = p.join(work, 'apply_update.sh');
    await File(script).writeAsString(
      Platform.isMacOS ? UpdateHelperScript.macos(params) : UpdateHelperScript.linux(params),
    );
    await Process.start('/bin/sh', [script], mode: ProcessStartMode.detached);
    return ApplyOutcome.launched;
  }

  /// Result line written by the helper for [tag], or null without a log.
  String? readResult(String tag) {
    try {
      final log = File(logPath(tag));
      if (!log.existsSync()) return null;
      return UpdateHelperScript.parseResult(log.readAsStringSync());
    } catch (_) {
      return null;
    }
  }

  /// Removes downloaded archives, staging folders and backups.
  Future<void> cleanUp() async {
    try {
      final dir = Directory(updatesDir);
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
