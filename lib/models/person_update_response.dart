class PersonUpdateResponse {
  final String message;
  final UpdatedPerson person;

  PersonUpdateResponse({
    required this.message,
    required this.person,
  });

  factory PersonUpdateResponse.fromJson(Map<String, dynamic> json) {
    return PersonUpdateResponse(
      message: json["message"] ?? "",
      person: UpdatedPerson.fromJson(json["person"] ?? {}),
    );
  }
}

class UpdatedPerson {
  final String personId;
  final String name;
  final String personCode;
  final Map<String, dynamic> info;
  final String imagePath;
  final double createdAt;

  UpdatedPerson({
    required this.personId,
    required this.name,
    required this.personCode,
    required this.info,
    required this.imagePath,
    required this.createdAt,
  });

  factory UpdatedPerson.fromJson(Map<String, dynamic> json) {
    return UpdatedPerson(
      personId: json["person_id"] ?? "",
      name: json["name"] ?? "",
      personCode: json["person_code"] ?? "",
      info: json["info"] ?? {},
      imagePath: json["registration_image_path"] ?? "",
      createdAt: (json["created_at"] ?? 0).toDouble(),
    );
  }
}