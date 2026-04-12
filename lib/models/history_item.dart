class HistoryItem {
  final String id;
  final double timestamp;
  final String? method;
  final String? path;
  final double? processTime;
  final int? statusCode;
  final String? type;
  final List<String> plates;
  final String? annotatedFrame;
  final String? imagePath;
  HistoryItem({
    required this.id,
    required this.timestamp,
    this.method,
    this.path,
    this.processTime,
    this.statusCode,
    this.type,
    required this.plates,
    this.annotatedFrame,
    this.imagePath,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? "",
      timestamp: (json['timestamp'] ?? 0).toDouble(),
      method: json['method'],
      path: json['path'],
      processTime: json['process_time']?.toDouble(),
      statusCode: json['status_code'],
      type: json['type'],
      plates: json['plates_found'] != null
          ? List<String>.from(json['plates_found'])
          : (json['summary'] != null &&
          json['summary']['plates_found'] != null
          ? List<String>.from(json['summary']['plates_found'])
          : []),
      annotatedFrame: json['annotated_frame'],
      imagePath: json['representative_image_path'],
    );
  }
}