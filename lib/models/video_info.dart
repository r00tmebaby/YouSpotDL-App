class VideoFormat {
  final String formatId;
  final String resolution;
  final String vcodec;
  final String acodec;
  final int? filesize;
  final String extension;
  final double? tbr;

  const VideoFormat({
    required this.formatId,
    required this.resolution,
    required this.vcodec,
    required this.acodec,
    this.filesize,
    required this.extension,
    this.tbr,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      formatId: json['format_id']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? '',
      vcodec: json['vcodec']?.toString() ?? 'none',
      acodec: json['acodec']?.toString() ?? 'none',
      filesize: json['filesize'] as int?,
      extension: json['ext']?.toString() ?? '',
      tbr: (json['tbr'] as num?)?.toDouble(),
    );
  }
}

class VideoInfo {
  final String title;
  final String? thumbnail;
  final int? duration;
  final String? uploader;
  final String url;
  final List<VideoFormat> formats;

  const VideoInfo({
    required this.title,
    this.thumbnail,
    this.duration,
    this.uploader,
    required this.url,
    required this.formats,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json, String originalUrl) {
    final formats = <VideoFormat>[];
    for (final f in (json['formats'] as List<dynamic>?) ?? []) {
      formats.add(VideoFormat.fromJson(f as Map<String, dynamic>));
    }

    return VideoInfo(
      title: json['title']?.toString() ?? 'Unknown',
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration'] as int?,
      uploader: json['uploader']?.toString(),
      url: originalUrl,
      formats: formats,
    );
  }
}
