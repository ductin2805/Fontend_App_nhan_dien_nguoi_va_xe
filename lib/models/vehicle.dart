import 'plate.dart';

class Vehicle {
  final int classId;
  final String className;
  final double confidence;
  final List<double> bbox;
  final Plate? plate;

  Vehicle({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.bbox,
    this.plate,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      classId: json['class_id'],
      className: json['class_name'] ?? "",
      confidence: (json['confidence'] as num).toDouble(),
      bbox: List<double>.from(
          json['bbox'].map((x) => (x as num).toDouble())),
      plate: json['plate'] != null
          ? Plate.fromJson(json['plate'])
          : null,
    );
  }
}