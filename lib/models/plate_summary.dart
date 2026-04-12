class PlateSummary {
  final String plate;
  final String className;
  final int count;
  final double firstSeenTime;
  final double lastSeenTime;
  final double confidence;
  PlateSummary({
    required this.plate,
    required this.className,
    required this.count,
    required this.firstSeenTime,
    required this.lastSeenTime,
    required this.confidence,
  });

  factory PlateSummary.fromJson(Map<String, dynamic> json) {
    return PlateSummary(
      plate: json['plate'],
      className: json['class_name'],
      count: json['count'],
      firstSeenTime: (json['first_seen_time'] as num).toDouble(),
      lastSeenTime: (json['last_seen_time'] as num).toDouble(),
      confidence: double.tryParse(json['confidence'].toString()) ?? 0.0,
    );
  }
}