import 'vehicle.dart';

class FrameResult {
  final int frameIndex;
  final double timestamp;
  final List<Vehicle> vehicles;
  final String? annotatedFrame;

  FrameResult({
    required this.frameIndex,
    required this.timestamp,
    required this.vehicles,
    this.annotatedFrame,
  });

  factory FrameResult.fromJson(Map<String, dynamic> json) {
    return FrameResult(
      frameIndex: json['frame_index'],
      timestamp: (json['timestamp'] as num).toDouble(),
      vehicles: (json['vehicles'] as List)
          .map((e) => Vehicle.fromJson(e))
          .toList(),
      annotatedFrame: json['annotated_frame'],
    );
  }
}