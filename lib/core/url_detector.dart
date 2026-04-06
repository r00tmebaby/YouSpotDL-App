enum DetectedUrlType { spotifyPlaylist, youtubePlaylist, youtubeVideo, genericVideo, unsupported }

DetectedUrlType detectUrlType(String url) {
  final lower = url.toLowerCase().trim();

  if (lower.contains('spotify.com/playlist/')) {
    return DetectedUrlType.spotifyPlaylist;
  }

  // YouTube playlist — covers /playlist?list= and /watch?v=xxx&list=xxx
  if (lower.contains('youtube.com/playlist') ||
      lower.contains('youtu.be/') && lower.contains('list=') ||
      lower.contains('youtube.com/watch') && lower.contains('list=')) {
    return DetectedUrlType.youtubePlaylist;
  }

  // Single YouTube video
  if (lower.contains('youtube.com/watch?v=') || lower.contains('youtu.be/')) {
    return DetectedUrlType.youtubeVideo;
  }

  // Any other HTTP(S) URL → hand off to yt-dlp (supports 1000+ sites)
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return DetectedUrlType.genericVideo;
  }

  return DetectedUrlType.unsupported;
}
