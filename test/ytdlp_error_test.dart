import 'package:flutter_test/flutter_test.dart';
import 'package:youspotdl/services/ytdlp_error.dart';

void main() {
  group('isStaleYtdlpError', () {
    test('matches the known stale-binary messages', () {
      expect(isStaleYtdlpError('ERROR: The page needs to be reloaded.'), isTrue);
      expect(isStaleYtdlpError('ERROR: unable to download: HTTP Error 403: Forbidden'), isTrue);
      expect(isStaleYtdlpError('ERROR: Sign in to confirm you are not a bot'), isTrue);
    });

    test('is case-insensitive', () {
      expect(isStaleYtdlpError('http error 403'), isTrue);
      expect(isStaleYtdlpError('SIGN IN TO CONFIRM'), isTrue);
    });

    test('ignores unrelated failures', () {
      expect(isStaleYtdlpError(''), isFalse);
      expect(isStaleYtdlpError('ERROR: Video unavailable'), isFalse);
      expect(isStaleYtdlpError('HTTP Error 404: Not Found'), isFalse);
    });
  });
}
