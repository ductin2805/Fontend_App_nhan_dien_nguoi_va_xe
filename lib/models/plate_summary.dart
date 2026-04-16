class PlateSummary {
  final String plate;
  final String className;
  final int count;
  final double firstSeenTime;
  final double lastSeenTime;
  final double confidence;

  final OwnerData? owner; // 👈 THÊM

  PlateSummary({
    required this.plate,
    required this.className,
    required this.count,
    required this.firstSeenTime,
    required this.lastSeenTime,
    required this.confidence,
    this.owner,
  });

  factory PlateSummary.fromJson(Map<String, dynamic> json) {
    return PlateSummary(
      plate: json['plate'],
      className: json['class_name'],
      count: json['count'],
      firstSeenTime: (json['first_seen_time'] as num).toDouble(),
      lastSeenTime: (json['last_seen_time'] as num).toDouble(),
      confidence: double.tryParse(json['confidence'].toString()) ?? 0.0,
      owner: json['owner'] != null
          ? OwnerData.fromJson(json['owner'])
          : null,
    );
  }
}

// 👇 OWNER MODEL
class OwnerData {
  final bool found;
  final String name;
  final String plate;
  final String matchType;

  final Map<String, dynamic> info; // 👈 thêm

  OwnerData({
    required this.found,
    required this.name,
    required this.plate,
    required this.matchType,
    required this.info,
  });

  factory OwnerData.fromJson(Map<String, dynamic> json) {
    return OwnerData(
      found: json['found'] ?? false,
      name: json['name'] ?? "",
      plate: json['plate'] ?? "",
      matchType: json['match_type'] ?? "",
      info: json['info'] ?? {},
    );
  }
}
