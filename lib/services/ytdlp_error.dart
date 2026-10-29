/// Output fragments that indicate yt-dlp is out of date with the site it is
/// downloading from, rather than a problem with the requested media itself.
const List<String> _staleYtdlpMarkers = [
  'the page needs to be reloaded',
  'http error 403',
  'sign in to confirm',
];

/// Returns true when [output] (yt-dlp stderr or an error message derived from
/// it) matches a failure that an updated yt-dlp binary is likely to fix.
bool isStaleYtdlpError(String output) {
  final lower = output.toLowerCase();
  return _staleYtdlpMarkers.any(lower.contains);
}
