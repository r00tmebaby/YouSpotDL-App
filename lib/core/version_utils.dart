/// Pure helpers for parsing and comparing release version strings and tags.
library;

/// Strips surrounding whitespace, a leading `v`/`V`, and any build (`+...`)
/// or pre-release (`-...`) suffix from [v].
String normalizeVersion(String v) {
  var s = v.trim();
  if (s.startsWith('v') || s.startsWith('V')) {
    s = s.substring(1);
  }
  final cut = s.indexOf(RegExp(r'[+-]'));
  if (cut >= 0) {
    s = s.substring(0, cut);
  }
  return s;
}

/// Compares two dotted version strings numerically.
///
/// Both inputs are normalized first. Each dot-separated segment contributes its
/// leading digits as an integer (a segment without leading digits counts as 0),
/// and the shorter version is padded with zeros. Returns a negative value when
/// [a] is older than [b], zero when they are equal, and a positive value when
/// [a] is newer.
int compareVersions(String a, String b) {
  final pa = _segments(normalizeVersion(a));
  final pb = _segments(normalizeVersion(b));
  final length = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < length; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) {
      return x - y;
    }
  }
  return 0;
}

/// Whether [candidate] is strictly newer than [current].
bool isNewerVersion(String candidate, String current) =>
    compareVersions(candidate, current) > 0;

/// Extracts the tag from a GitHub-style `/releases/tag/<tag>` URL or path.
///
/// Query strings, fragments and trailing slashes are ignored, and the tag is
/// percent-decoded. Returns null when [location] is null, empty, or does not
/// contain `/releases/tag/` followed by a non-empty tag.
String? tagFromLocation(String? location) {
  if (location == null || location.isEmpty) {
    return null;
  }
  const marker = '/releases/tag/';
  final index = location.indexOf(marker);
  if (index < 0) {
    return null;
  }
  var rest = location.substring(index + marker.length);
  final end = rest.indexOf(RegExp(r'[?#/]'));
  if (end >= 0) {
    rest = rest.substring(0, end);
  }
  if (rest.isEmpty) {
    return null;
  }
  try {
    return Uri.decodeComponent(rest);
  } on FormatException {
    return rest;
  }
}

/// Splits [v] on dots and reads each segment's leading digits as an integer.
List<int> _segments(String v) {
  final digits = RegExp(r'^\d+');
  return v.split('.').map((s) {
    final m = digits.firstMatch(s);
    return m == null ? 0 : int.parse(m.group(0)!);
  }).toList();
}
