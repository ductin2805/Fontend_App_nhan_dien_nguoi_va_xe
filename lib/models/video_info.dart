class VideoInfo {
  final int totalFrames;
  final double fps;
  final int width;
  final int height;
  final double duration;

  VideoInfo({
    required this.totalFrames,
    required this.fps,
    required this.width,
    required this.height,
    required this.duration,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      totalFrames: json['total_frames'],
      fps: (json['fps'] as num).toDouble(),
      width: json['width'],
      height: json['height'],
      duration: (json['duration'] as num).toDouble(),
    );
  }
}