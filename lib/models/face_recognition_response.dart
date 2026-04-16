class FaceRecognitionResponse {
  final int totalFaces;
  final double threshold;
  final String annotatedImage;
  final List<FaceData> faces;

  FaceRecognitionResponse({
    required this.totalFaces,
    required this.threshold,
    required this.annotatedImage,
    required this.faces,
  });

  factory FaceRecognitionResponse.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionResponse(
      totalFaces: json['total_faces'] ?? 0,
      threshold: (json['threshold'] ?? 0).toDouble(),
      annotatedImage: json['annotated_image'] ?? "",
      faces: (json['faces'] as List? ?? [])
          .map((e) => FaceData.fromJson(e))
          .toList(),
    );
  }
}

// ================= FACE =================
class FaceData {
  final List<int> bbox;
  final bool isKnown;
  final double matchScore;

  final PersonData? person;
  final List<PersonData> topMatches;

  FaceData({
    required this.bbox,
    required this.isKnown,
    required this.matchScore,
    this.person,
    required this.topMatches,
  });

  factory FaceData.fromJson(Map<String, dynamic> json) {
    return FaceData(
      bbox: List<int>.from(json['bbox'] ?? []),
      isKnown: json['is_known'] ?? false,
      matchScore: (json['match_score'] ?? 0).toDouble(),
      person: json['person'] != null
          ? PersonData.fromJson(json['person'])
          : null,
      topMatches: (json['top_matches'] as List? ?? [])
          .map((e) => PersonData.fromJson(e))
          .toList(),
    );
  }
}

// ================= PERSON =================
class PersonData {
  final String personId;
  final String name;
  final String personCode;
  final PersonInfo info;
  final double matchScore;
  final bool isKnown;

  PersonData({
    required this.personId,
    required this.name,
    required this.personCode,
    required this.info,
    required this.matchScore,
    required this.isKnown,
  });

  factory PersonData.fromJson(Map<String, dynamic> json) {
    return PersonData(
      personId: json['person_id'] ?? "",
      name: json['name'] ?? "",
      personCode: json['person_code'] ?? "",
      info: PersonInfo.fromJson(json['info'] ?? {}),
      matchScore: (json['match_score'] ?? 0).toDouble(),
      isKnown: json['is_known'] ?? false,
    );
  }
}

// ================= INFO =================
class PersonInfo {
  final String department;
  final String role;
  final String phone;
  final String address;
  final String age;
  final String dateOfBirth;
  final String cccd;
  final String plateNumber;
  final String vehiclePlates;
  PersonInfo({
    required this.department,
    required this.role,
    required this.phone,
    required this.address,
    required this.age,
    required this.dateOfBirth,
    required this.cccd,
    required this.plateNumber,
    required this.vehiclePlates,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      department: json['department'] ?? "",
      role: json['role'] ?? "",
      phone: json['phone'] ?? "",
      address: json['address'] ?? "",
      age: json['age'] ?? "",
      dateOfBirth: json['date_of_birth'] ?? "",
      cccd: json['cccd'] ?? "",
      vehiclePlates: json['vehicle_plates'] ?? "",
      plateNumber: json['plate_number'] ?? "",
    );
  }
}