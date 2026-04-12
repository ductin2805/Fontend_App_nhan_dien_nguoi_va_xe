import 'package:ai_traffic_app/models/plate_summary.dart';
import 'video_info.dart';
import 'processing_info.dart';
import 'frame_result.dart';

class RecognitionResponse {
  final VideoInfo videoInfo;
  final ProcessingInfo processingInfo;
  final List<PlateSummary> plates;
  final List<FrameResult> results;
  RecognitionResponse({
    required this.videoInfo,
    required this.processingInfo,
    required this.results,
    required this.plates,
  });

  factory RecognitionResponse.fromJson(Map<String, dynamic> json) {
    return RecognitionResponse(
      videoInfo: VideoInfo.fromJson(json['video_info']),
      processingInfo: ProcessingInfo.fromJson(json['processing_info']),
      results: (json['results'] as List)
          .map((e) => FrameResult.fromJson(e))
          .toList(),
      plates: (json['plates'] as List? ?? [])
          .map((e) => PlateSummary.fromJson(e))
          .toList(),
    );
  }

}