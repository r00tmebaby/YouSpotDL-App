import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Progress of a long-running download or install step.
class DownloadProgress {
  /// Completion from 0.0 to 1.0.
  final double fraction;

  /// Human-readable status, for example "Downloading yt-dlp (3.2 / 18.0 MB)".
  final String label;

  const DownloadProgress(this.fraction, this.label);
}

/// User agent sent to GitHub, which rejects requests without one.
const String httpUserAgent = 'YouSpotDL-Updater';

/// Streams [url] into [dest], following redirects, and reports progress.
///
/// Uses dart:io HttpClient because GitHub release downloads redirect to a CDN
/// and the redirect must be followed for the body to arrive. A partially
/// written file is deleted when the download fails.
Stream<DownloadProgress> downloadToFile(
  String url,
  String dest,
  String label, {
  Duration stallTimeout = const Duration(seconds: 60),
}) async* {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..userAgent = httpUserAgent;
  final file = File(dest);
  IOSink? sink;
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.followRedirects = true;
    request.maxRedirects = 10;

    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'HTTP ${response.statusCode} while downloading $label',
        uri: Uri.parse(url),
      );
    }

    final total = response.contentLength;
    var received = 0;

    await Directory(p.dirname(dest)).create(recursive: true);
    sink = file.openWrite();

    await for (final chunk in response.timeout(stallTimeout)) {
      sink.add(chunk);
      received += chunk.length;
      final mb = (received / 1048576).toStringAsFixed(1);
      final totalMb =
          total > 0 ? ' / ${(total / 1048576).toStringAsFixed(1)} MB' : '';
      yield DownloadProgress(
        total > 0
            ? received / total
            : (received / (30 * 1048576)).clamp(0.0, 0.99),
        '$label ($mb MB$totalMb)',
      );
    }
    await sink.close();
    sink = null;
    if (total > 0 && received != total) {
      throw HttpException(
        'Incomplete download of $label: $received of $total bytes',
        uri: Uri.parse(url),
      );
    }
    yield DownloadProgress(1.0, '$label done');
  } catch (_) {
    await sink?.close().catchError((_) {});
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
    rethrow;
  } finally {
    client.close(force: true);
  }
}
