/// Tests for [UpdatePrefs] throttling, caching, snooze and tag bookkeeping.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youspotdl/services/update_prefs.dart';

void main() {
  final base = DateTime(2026, 10, 28, 12);

  Future<UpdatePrefs> makePrefs({
    Map<String, Object> initial = const {},
    DateTime Function()? clock,
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return UpdatePrefs(prefs, clock: clock ?? () => base);
  }

  group('isDue', () {
    const interval = Duration(hours: 24);

    test('is due when no record exists', () {
      expect(UpdatePrefs.isDue(null, base, interval), isTrue);
    });

    test('is due when the record is in the future (clock skew)', () {
      final future = base.add(const Duration(hours: 1));
      expect(
        UpdatePrefs.isDue(future.millisecondsSinceEpoch, base, interval),
        isTrue,
      );
    });

    test('is not due when the last check is below the interval', () {
      final last = base.subtract(const Duration(hours: 23, minutes: 59));
      expect(
        UpdatePrefs.isDue(last.millisecondsSinceEpoch, base, interval),
        isFalse,
      );
    });

    test('is due exactly at the interval', () {
      final last = base.subtract(interval);
      expect(
        UpdatePrefs.isDue(last.millisecondsSinceEpoch, base, interval),
        isTrue,
      );
    });

    test('is due when the last check is above the interval', () {
      final last = base.subtract(const Duration(hours: 25));
      expect(
        UpdatePrefs.isDue(last.millisecondsSinceEpoch, base, interval),
        isTrue,
      );
    });
  });

  group('yt-dlp check', () {
    test('is due on first run and not after marking', () async {
      final prefs = await makePrefs();
      expect(prefs.isYtdlpCheckDue, isTrue);
      await prefs.markYtdlpChecked();
      expect(prefs.isYtdlpCheckDue, isFalse);
      final stored = await SharedPreferences.getInstance();
      expect(
        stored.getInt(UpdatePrefs.ytdlpLastCheckKey),
        base.millisecondsSinceEpoch,
      );
    });

    test('becomes due after the interval elapses', () async {
      var now = base;
      final prefs = await makePrefs(clock: () => now);
      await prefs.markYtdlpChecked();
      now = base.add(UpdatePrefs.checkInterval);
      expect(prefs.isYtdlpCheckDue, isTrue);
    });
  });

  group('app check', () {
    test('is due on first run and not after marking', () async {
      final prefs = await makePrefs();
      expect(prefs.isAppCheckDue, isTrue);
      await prefs.markAppChecked();
      expect(prefs.isAppCheckDue, isFalse);
    });

    test('is tracked independently from yt-dlp', () async {
      final prefs = await makePrefs();
      await prefs.markYtdlpChecked();
      expect(prefs.isAppCheckDue, isTrue);
    });
  });

  group('cached release', () {
    test('set, read and remove', () async {
      final prefs = await makePrefs();
      expect(prefs.cachedRelease, isNull);
      await prefs.setCachedRelease('{"tag":"v1.0.3"}');
      expect(prefs.cachedRelease, '{"tag":"v1.0.3"}');
      await prefs.setCachedRelease(null);
      expect(prefs.cachedRelease, isNull);
    });
  });

  group('snooze', () {
    test('is inactive by default', () async {
      final prefs = await makePrefs();
      expect(prefs.isSnoozed, isFalse);
    });

    test('is active until the check interval expires', () async {
      var now = base;
      final prefs = await makePrefs(clock: () => now);
      await prefs.snooze();
      expect(prefs.isSnoozed, isTrue);

      now = base.add(UpdatePrefs.checkInterval - const Duration(minutes: 1));
      expect(prefs.isSnoozed, isTrue);

      now = base.add(UpdatePrefs.checkInterval);
      expect(prefs.isSnoozed, isFalse);
    });

    test('clearSnooze removes an active snooze', () async {
      final prefs = await makePrefs();
      await prefs.snooze();
      await prefs.clearSnooze();
      expect(prefs.isSnoozed, isFalse);
    });
  });

  group('applying tag', () {
    test('set and remove', () async {
      final prefs = await makePrefs();
      expect(prefs.applyingTag, isNull);
      await prefs.setApplyingTag('v1.0.3');
      expect(prefs.applyingTag, 'v1.0.3');
      await prefs.setApplyingTag(null);
      expect(prefs.applyingTag, isNull);
    });
  });

  group('load', () {
    test('wraps the stored preferences', () async {
      SharedPreferences.setMockInitialValues({
        UpdatePrefs.applyingTagKey: 'v9.9.9',
      });
      final prefs = await UpdatePrefs.load();
      expect(prefs.applyingTag, 'v9.9.9');
    });
  });
}
