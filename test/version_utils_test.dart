/// Unit tests for the release version and tag helpers in version_utils.dart.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:youspotdl/core/version_utils.dart';

void main() {
  group('normalizeVersion', () {
    test('drops leading v and V', () {
      expect(normalizeVersion('v1.0.2'), '1.0.2');
      expect(normalizeVersion('V1.0.2'), '1.0.2');
    });

    test('drops build and pre-release suffixes', () {
      expect(normalizeVersion('1.0.2+2'), '1.0.2');
      expect(normalizeVersion('v1.0.2-beta.1'), '1.0.2');
      expect(normalizeVersion('1.0.2-rc+5'), '1.0.2');
    });

    test('trims whitespace', () {
      expect(normalizeVersion('  v1.2.3 \n'), '1.2.3');
    });

    test('handles empty input', () {
      expect(normalizeVersion(''), '');
      expect(normalizeVersion('   '), '');
    });
  });

  group('compareVersions', () {
    test('matches design examples', () {
      expect(compareVersions('2026.10.26.123456', '2026.10.26') > 0, isTrue);
      expect(compareVersions('v1.0.10', '1.0.9') > 0, isTrue);
      expect(compareVersions('1.0.2+2', '1.0.2'), 0);
    });

    test('compares numerically, not lexically', () {
      expect(compareVersions('1.10.0', '1.9.0') > 0, isTrue);
      expect(compareVersions('1.9.0', '1.10.0') < 0, isTrue);
    });

    test('pads shorter versions with zeros', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0.1', '1.0') > 0, isTrue);
    });

    test('ignores v prefix and suffixes when comparing', () {
      expect(compareVersions('v2.0.0-beta', '1.9.9'), greaterThan(0));
      expect(compareVersions('V1.2.3', 'v1.2.3+9'), 0);
    });

    test('treats non-numeric segments as leading digits or zero', () {
      expect(compareVersions('1.2a.0', '1.2.0'), 0);
      expect(compareVersions('1.x', '1.0'), 0);
      expect(compareVersions('1.x1', '1.1') < 0, isTrue);
      expect(compareVersions('1.5abc', '1.4zzz') > 0, isTrue);
    });

    test('treats empty strings as zero', () {
      expect(compareVersions('', ''), 0);
      expect(compareVersions('', '0'), 0);
      expect(compareVersions('', '0.0.1') < 0, isTrue);
    });
  });

  group('isNewerVersion', () {
    test('is true only when candidate is strictly newer', () {
      expect(isNewerVersion('1.0.3', '1.0.2'), isTrue);
      expect(isNewerVersion('1.0.2', '1.0.2'), isFalse);
      expect(isNewerVersion('1.0.1', '1.0.2'), isFalse);
      expect(isNewerVersion('v1.0.10', '1.0.9'), isTrue);
      expect(isNewerVersion('1.0.2+2', '1.0.2'), isFalse);
    });
  });

  group('tagFromLocation', () {
    test('extracts tag from absolute URL', () {
      expect(
        tagFromLocation('https://github.com/owner/repo/releases/tag/v1.0.2'),
        'v1.0.2',
      );
    });

    test('extracts tag from path-only location', () {
      expect(tagFromLocation('/owner/repo/releases/tag/v1.0.2'), 'v1.0.2');
    });

    test('percent-decodes the tag', () {
      expect(
        tagFromLocation('/owner/repo/releases/tag/v1.0.2%2Bbuild'),
        'v1.0.2+build',
      );
    });

    test('ignores trailing slash', () {
      expect(
        tagFromLocation('https://github.com/o/r/releases/tag/v1.0.2/'),
        'v1.0.2',
      );
    });

    test('ignores query string and fragment', () {
      expect(
        tagFromLocation('https://github.com/o/r/releases/tag/v1.0.2?x=1'),
        'v1.0.2',
      );
      expect(
        tagFromLocation('https://github.com/o/r/releases/tag/v1.0.2#notes'),
        'v1.0.2',
      );
    });

    test('returns null for null input', () {
      expect(tagFromLocation(null), isNull);
    });

    test('returns null for empty input', () {
      expect(tagFromLocation(''), isNull);
    });

    test('returns null when marker is absent', () {
      expect(tagFromLocation('https://github.com/o/r/releases'), isNull);
      expect(tagFromLocation('https://example.com/tag/v1'), isNull);
    });

    test('returns null when tag segment is empty', () {
      expect(tagFromLocation('https://github.com/o/r/releases/tag/'), isNull);
      expect(tagFromLocation('/o/r/releases/tag/?x=1'), isNull);
    });
  });
}
