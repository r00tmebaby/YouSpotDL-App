/// Persistent bookkeeping for update checks: throttle timestamps, the cached
/// app release, snooze state and the tag of an in-flight app update.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Reads and writes update-related values in [SharedPreferences].
class UpdatePrefs {
  /// Preference key holding the last yt-dlp check time (ms since epoch).
  static const ytdlpLastCheckKey = 'updates.ytdlp.lastCheckMs';

  /// Preference key holding the last app update check time (ms since epoch).
  static const appLastCheckKey = 'updates.app.lastCheckMs';

  /// Preference key holding the cached app release as JSON.
  static const cachedReleaseKey = 'updates.app.cachedRelease';

  /// Preference key holding the snooze expiry time (ms since epoch).
  static const snoozedUntilKey = 'updates.app.snoozedUntilMs';

  /// Preference key holding the tag of an app update that is being applied.
  static const applyingTagKey = 'updates.app.applyingTag';

  /// Minimum time between automatic update checks.
  static const checkInterval = Duration(hours: 24);

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  /// Creates a store backed by [prefs]. [clock] defaults to [DateTime.now]
  /// and exists so tests can control time.
  UpdatePrefs(SharedPreferences prefs, {DateTime Function()? clock})
    : _prefs = prefs,
      _clock = clock ?? DateTime.now;

  /// Loads the shared preferences instance and wraps it.
  static Future<UpdatePrefs> load() async {
    return UpdatePrefs(await SharedPreferences.getInstance());
  }

  /// Returns true when a check recorded at [lastMs] is due at [now].
  ///
  /// A missing record is always due. A timestamp in the future (clock skew)
  /// is treated as due so a bad clock cannot suppress checks forever.
  static bool isDue(int? lastMs, DateTime now, Duration interval) {
    if (lastMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (last.isAfter(now)) return true;
    return now.difference(last) >= interval;
  }

  /// Whether the yt-dlp update check is due.
  bool get isYtdlpCheckDue =>
      isDue(_prefs.getInt(ytdlpLastCheckKey), _clock(), checkInterval);

  /// Records that the yt-dlp update check has just run.
  Future<void> markYtdlpChecked() =>
      _prefs.setInt(ytdlpLastCheckKey, _clock().millisecondsSinceEpoch);

  /// Whether the app update check is due.
  bool get isAppCheckDue =>
      isDue(_prefs.getInt(appLastCheckKey), _clock(), checkInterval);

  /// Records that the app update check has just run.
  Future<void> markAppChecked() =>
      _prefs.setInt(appLastCheckKey, _clock().millisecondsSinceEpoch);

  /// The cached app release JSON, or null when none is stored.
  String? get cachedRelease => _prefs.getString(cachedReleaseKey);

  /// Stores [json] as the cached app release. Passing null removes it.
  Future<void> setCachedRelease(String? json) => json == null
      ? _prefs.remove(cachedReleaseKey)
      : _prefs.setString(cachedReleaseKey, json);

  /// Whether the user has snoozed the app update prompt and the snooze has
  /// not yet expired.
  bool get isSnoozed {
    final until = _prefs.getInt(snoozedUntilKey);
    return until != null &&
        DateTime.fromMillisecondsSinceEpoch(until).isAfter(_clock());
  }

  /// Snoozes the app update prompt for [checkInterval].
  Future<void> snooze() => _prefs.setInt(
    snoozedUntilKey,
    _clock().add(checkInterval).millisecondsSinceEpoch,
  );

  /// Removes any active snooze.
  Future<void> clearSnooze() => _prefs.remove(snoozedUntilKey);

  /// The tag of the app update currently being applied, or null.
  String? get applyingTag => _prefs.getString(applyingTagKey);

  /// Stores [tag] as the update being applied. Passing null removes it.
  Future<void> setApplyingTag(String? tag) => tag == null
      ? _prefs.remove(applyingTagKey)
      : _prefs.setString(applyingTagKey, tag);
}
