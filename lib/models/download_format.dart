class DownloadFormat {
  final String label;
  final String ytDlpSelector;
  final String outputExt;
  final bool audioOnly;

  const DownloadFormat({
    required this.label,
    required this.ytDlpSelector,
    required this.outputExt,
    required this.audioOnly,
  });

  static const audioFormats = <DownloadFormat>[
    DownloadFormat(
      label: 'MP3 Best Quality',
      ytDlpSelector: 'bestaudio',
      outputExt: 'mp3',
      audioOnly: true,
    ),
    DownloadFormat(
      label: 'MP3 192kbps',
      ytDlpSelector: 'bestaudio[abr<=192]',
      outputExt: 'mp3',
      audioOnly: true,
    ),
  ];

  // Prefer H264 (vcodec^=avc) + m4a so the merged MP4 is previewable on Windows natively.
  static const videoFormats = <DownloadFormat>[
    DownloadFormat(
      label: 'MP4 1080p',
      ytDlpSelector: 'bestvideo[vcodec^=avc][height<=1080][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=1080]+bestaudio/best[height<=1080]',
      outputExt: 'mp4',
      audioOnly: false,
    ),
    DownloadFormat(
      label: 'MP4 720p',
      ytDlpSelector: 'bestvideo[vcodec^=avc][height<=720][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=720][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=720]+bestaudio/best[height<=720]',
      outputExt: 'mp4',
      audioOnly: false,
    ),
    DownloadFormat(
      label: 'MP4 480p',
      ytDlpSelector: 'bestvideo[vcodec^=avc][height<=480][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=480][ext=mp4]+bestaudio[ext=m4a]/bestvideo[height<=480]+bestaudio/best[height<=480]',
      outputExt: 'mp4',
      audioOnly: false,
    ),
    DownloadFormat(
      label: 'Best Available',
      ytDlpSelector: 'bestvideo[vcodec^=avc][ext=mp4]+bestaudio[ext=m4a]/bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best',
      outputExt: 'mp4',
      audioOnly: false,
    ),
  ];
}
