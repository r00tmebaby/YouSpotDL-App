import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/version_utils.dart';
import '../models/download_task.dart' show DownloadStatus;
import '../services/app_update_service.dart';
import '../services/update_helper_script.dart';
import '../services/update_prefs.dart';
import '../services/ytdlp_update_service.dart';
import 'download_provider.dart';

/// User-writable tools directory, resolved before the app starts.
final toolsDirProvider = Provider<String>(
  (ref) => throw UnimplementedError('toolsDirProvider must be overridden'),
);

/// Update bookkeeping in shared preferences, loaded before the app starts.
final updatePrefsProvider = Provider<UpdatePrefs>(
  (ref) => throw UnimplementedError('updatePrefsProvider must be overridden'),
);

final ytdlpUpdateServiceProvider = Provider<YtdlpUpdateService>(
  (ref) => YtdlpUpdateService(toolsDir: ref.watch(toolsDirProvider)),
);

/// The tools directory lives in the app support directory, next to `updates/`.
final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(appSupportDir: p.dirname(ref.watch(toolsDirProvider))),
);

final ytdlpUpdaterProvider =
    StateNotifierProvider<YtdlpUpdater, YtdlpUpdateState>(
  (ref) => YtdlpUpdater(
    ref,
    ref.watch(ytdlpUpdateServiceProvider),
    ref.watch(updatePrefsProvider),
  ),
);

final appUpdateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>(
  (ref) => AppUpdateNotifier(
    ref.watch(appUpdateServiceProvider),
    ref.watch(updatePrefsProvider),
    hasActiveDownloads: () => ref
        .read(downloadProvider)
        .tasks
        .any((task) => isActiveDownloadStatus(task.status)),
  ),
);

/// Whether a task in [status] may still write files or start yt-dlp.
bool isActiveDownloadStatus(DownloadStatus status) =>
    status == DownloadStatus.pending ||
    status == DownloadStatus.fetching ||
    status == DownloadStatus.downloading;

// ── yt-dlp ─────────────────────────────────────────────────────────────────

enum YtdlpUpdatePhase { idle, checking, downloading, installed, upToDate, failed }

class YtdlpUpdateState {
  final YtdlpUpdatePhase phase;
  final double fraction;
  final String? installedVersion;
  final String? latestVersion;
  final String? message;

  const YtdlpUpdateState({
    this.phase = YtdlpUpdatePhase.idle,
    this.fraction = 0,
    this.installedVersion,
    this.latestVersion,
    this.message,
  });

  bool get isBusy =>
      phase == YtdlpUpdatePhase.checking || phase == YtdlpUpdatePhase.downloading;

  YtdlpUpdateState copyWith({
    YtdlpUpdatePhase? phase,
    double? fraction,
    String? installedVersion,
    String? latestVersion,
    String? message,
  }) =>
      YtdlpUpdateState(
        phase: phase ?? this.phase,
        fraction: fraction ?? this.fraction,
        installedVersion: installedVersion ?? this.installedVersion,
        latestVersion: latestVersion ?? this.latestVersion,
        message: message,
      );
}

/// Keeps yt-dlp current. Startup checks are throttled to once per
/// [UpdatePrefs.checkInterval] and fail silently; a missing binary is always
/// installed, and a forced check (the Settings button) reports every outcome.
class YtdlpUpdater extends StateNotifier<YtdlpUpdateState> {
  YtdlpUpdater(this._ref, this._service, this._prefs)
      : super(const YtdlpUpdateState());

  final Ref _ref;
  final YtdlpUpdateService _service;
  final UpdatePrefs _prefs;
  Future<void>? _running;

  /// Checks for a newer yt-dlp and installs it. A call made while another is
  /// running waits for that one instead of starting a second download.
  Future<void> checkAndUpdate({bool force = false}) =>
      _running ??= _run(force).whenComplete(() => _running = null);

  /// Clears a finished or failed status once the user has seen it.
  void acknowledge() {
    if (state.isBusy) return;
    state = YtdlpUpdateState(
      installedVersion: state.installedVersion,
      latestVersion: state.latestVersion,
    );
  }

  Future<void> _run(bool force) async {
    final downloads = _ref.read(downloadServiceProvider);
    final installed = await downloads.getYtdlpVersion();
    if (!force && installed != null && !_prefs.isYtdlpCheckDue) {
      state = YtdlpUpdateState(installedVersion: installed);
      return;
    }

    state = YtdlpUpdateState(
      phase: YtdlpUpdatePhase.checking,
      installedVersion: installed,
      message: 'Checking for a new yt-dlp',
    );
    final String latest;
    try {
      latest = await _service.latestVersion();
      await _prefs.markYtdlpChecked();
    } catch (e) {
      state = YtdlpUpdateState(
        phase: force ? YtdlpUpdatePhase.failed : YtdlpUpdatePhase.idle,
        installedVersion: installed,
        message: force ? 'Could not check for a new yt-dlp: $e' : null,
      );
      return;
    }

    if (installed != null && compareVersions(installed, latest) >= 0) {
      state = YtdlpUpdateState(
        phase: YtdlpUpdatePhase.upToDate,
        installedVersion: installed,
        latestVersion: latest,
        message: 'yt-dlp $installed is up to date',
      );
      return;
    }

    state = state.copyWith(
      phase: YtdlpUpdatePhase.downloading,
      latestVersion: latest,
      message: 'Updating yt-dlp to $latest',
    );
    try {
      await for (final progress in _service.install()) {
        state = state.copyWith(fraction: progress.fraction, message: progress.label);
      }
    } catch (e) {
      state = state.copyWith(
        phase: YtdlpUpdatePhase.failed,
        message: 'yt-dlp update failed: $e',
      );
      return;
    }

    downloads.resetToolCache();
    _ref
      ..invalidate(toolsInfoProvider)
      ..invalidate(toolStatusProvider);
    final now = await downloads.getYtdlpVersion();
    state = YtdlpUpdateState(
      phase: YtdlpUpdatePhase.installed,
      fraction: 1,
      installedVersion: now,
      latestVersion: latest,
      message: 'yt-dlp updated to ${now ?? latest}',
    );
  }
}

// ── App ────────────────────────────────────────────────────────────────────

enum AppUpdatePhase { idle, checking, upToDate, available, downloading, launching, failed }

class AppUpdateState {
  final AppUpdatePhase phase;
  final ReleaseInfo? release;
  final double fraction;
  final String? message;

  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.release,
    this.fraction = 0,
    this.message,
  });

  /// Whether the banner is shown: an update is offered, in progress, or
  /// failed after the user started it.
  bool get showBanner =>
      release != null &&
      (phase == AppUpdatePhase.available ||
          phase == AppUpdatePhase.downloading ||
          phase == AppUpdatePhase.launching ||
          phase == AppUpdatePhase.failed);

  bool get isBusy =>
      phase == AppUpdatePhase.checking ||
      phase == AppUpdatePhase.downloading ||
      phase == AppUpdatePhase.launching;
}

/// Offers new app releases and applies one when the user asks. Never updates
/// without the user pressing "Update now".
class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier(
    this._service,
    this._prefs, {
    void Function(int)? exitApp,
    bool Function()? hasActiveDownloads,
    Future<bool> Function(Uri url)? openUrl,
  })  : _exitApp = exitApp ?? exit,
        _hasActiveDownloads = hasActiveDownloads ?? _noActiveDownloads,
        _openUrl = openUrl ?? _launchExternal,
        super(const AppUpdateState());

  /// Message shown when an update is requested while downloads are running.
  static const activeDownloadsMessage =
      'Finish or cancel the active downloads first, then update.';

  final AppUpdateService _service;
  final UpdatePrefs _prefs;
  final void Function(int) _exitApp;
  final bool Function() _hasActiveDownloads;
  final Future<bool> Function(Uri url) _openUrl;

  static bool _noActiveDownloads() => false;

  static Future<bool> _launchExternal(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// Whether "Update now" replaces the app in place. When false the release
  /// page is opened and the user installs the new version manually.
  bool get supportsInPlaceUpdate => _service.supportsInPlaceUpdate;

  /// Looks for a newer release. Automatic checks use the cached release
  /// within the throttle window and stay silent on errors; [manual] checks
  /// always query GitHub, clear a snooze and report failures.
  Future<void> check({bool manual = false}) async {
    if (state.isBusy) return;

    if (!manual && !_prefs.isAppCheckDue) {
      final cached = ReleaseInfo.tryFromJson(_prefs.cachedRelease);
      if (cached != null && isNewerVersion(cached.version, appVersion) && !_prefs.isSnoozed) {
        state = AppUpdateState(phase: AppUpdatePhase.available, release: cached);
      }
      return;
    }

    if (manual) {
      state = AppUpdateState(phase: AppUpdatePhase.checking, release: state.release);
    }
    final ReleaseInfo? release;
    try {
      release = await _service.fetchLatestRelease();
      await _prefs.markAppChecked();
      await _prefs.setCachedRelease(release == null ? null : jsonEncode(release.toJson()));
    } catch (e) {
      state = manual
          ? AppUpdateState(phase: AppUpdatePhase.failed, message: 'Could not check for updates: $e')
          : const AppUpdateState();
      return;
    }

    if (release == null || !isNewerVersion(release.version, appVersion)) {
      state = AppUpdateState(
        phase: AppUpdatePhase.upToDate,
        message: 'YouSpotDL $appVersion is the latest version',
      );
      return;
    }
    if (manual) await _prefs.clearSnooze();
    state = manual || !_prefs.isSnoozed
        ? AppUpdateState(phase: AppUpdatePhase.available, release: release)
        : AppUpdateState(release: release);
  }

  /// Downloads, stages and hands the release to the helper, then exits. On
  /// platforms without in-place updates it opens the release page instead.
  /// Refuses to start while downloads are running, because the app exits.
  Future<void> startUpdate() async {
    final release = state.release;
    if (release == null || state.isBusy) return;

    if (!_service.supportsInPlaceUpdate) {
      await openReleasePage();
      return;
    }
    if (_hasActiveDownloads()) {
      _fail(release, activeDownloadsMessage);
      return;
    }

    state = AppUpdateState(phase: AppUpdatePhase.downloading, release: release);
    try {
      await for (final progress in _service.download(release)) {
        state = AppUpdateState(
          phase: AppUpdatePhase.downloading,
          release: release,
          fraction: progress.fraction,
          message: progress.label,
        );
      }
      state = AppUpdateState(
        phase: AppUpdatePhase.launching,
        release: release,
        fraction: 1,
        message: 'Installing YouSpotDL ${release.version}',
      );
      final staged = await _service.stage(release);
      // Recorded before the helper starts so the next launch can report.
      await _prefs.setApplyingTag(release.tag);
      final outcome = await _service.apply(release, staged);
      switch (outcome) {
        case ApplyOutcome.launched:
          _exitApp(0);
        case ApplyOutcome.elevationDeclined:
          await _prefs.setApplyingTag(null);
          _fail(release, 'Administrator permission was declined. '
              'Download the update from the release page instead.');
        case ApplyOutcome.notWritable:
          await _prefs.setApplyingTag(null);
          _fail(release, 'The install folder is not writable. '
              'Download the update from the release page instead.');
      }
    } catch (e) {
      await _prefs.setApplyingTag(null);
      _fail(release, 'Update failed: $e');
    }
  }

  void _fail(ReleaseInfo release, String message) {
    state = AppUpdateState(phase: AppUpdatePhase.failed, release: release, message: message);
  }

  /// Hides the banner for [UpdatePrefs.checkInterval].
  Future<void> later() async {
    await _prefs.snooze();
    state = AppUpdateState(release: state.release);
  }

  Future<void> openReleasePage() async {
    final url = state.release?.htmlUrl ?? AppUpdateService.releasesPage;
    await _openUrl(Uri.parse(url));
  }

  /// Reports how the last self-update ended, once, and clears its files when
  /// it succeeded. Returns null when no update was pending.
  Future<String?> consumePreviousResult() async {
    final tag = _prefs.applyingTag;
    if (tag == null) return null;
    await _prefs.setApplyingTag(null);

    final result = _service.readResult(tag);
    if (compareVersions(appVersion, tag) >= 0) {
      await _service.cleanUp();
      return 'YouSpotDL was updated to $appVersion';
    }
    final reason = result == null || result == UpdateHelperScript.resultSuccess
        ? 'the update helper did not finish'
        : result;
    return 'Update to ${normalizeVersion(tag)} failed: $reason. '
        'Log: ${_service.logPath(tag)}';
  }
}

/// Outcome of the self-update applied before this launch, shown once.
final previousUpdateResultProvider = StateProvider<String?>((ref) => null);
