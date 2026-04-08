import 'plate_detail.dart';

class Plate {
  final String text;
  final double confidence;
  final List<PlateDetail> details;

  Plate({
    required this.text,
    required this.confidence,
    required this.details,
  });

  factory Plate.fromJson(Map<String, dynamic> json) {
    return Plate(
      text: json['text'] ?? "",
      confidence: (json['confidence'] as num).toDouble(),
      details: (json['details'] as List? ?? [])
          .map((e) => PlateDetail.fromJson(e))
          .toList(),
    );
  }
}