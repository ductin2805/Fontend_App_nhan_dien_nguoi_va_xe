class ProcessingInfo {
  final int processedFrames;
  final int frameSkip;
  final int maxFrames;
  final int framesProcessed;

  ProcessingInfo({
    required this.processedFrames,
    required this.frameSkip,
    required this.maxFrames,
    required this.framesProcessed,
  });

  factory ProcessingInfo.fromJson(Map<String, dynamic> json) {
    return ProcessingInfo(
      processedFrames: json['processed_frames'],
      frameSkip: json['frame_skip'],
      maxFrames: json['max_frames'],
      framesProcessed: json['frames_processed'],
    );
  }
}