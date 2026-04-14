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
  final PersonInfo info;
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
      info: PersonInfo.fromJson(json["info"] ?? {}),
      imagePath: json["registration_image_path"] ?? "",
      createdAt: (json["created_at"] ?? 0).toDouble(),
    );
  }
}

class PersonInfo {
  final String department;
  final String role;
  final String phone;
  final String address;
  final String age;
  final String dob;
  final String cccd;

  PersonInfo({
    required this.department,
    required this.role,
    required this.phone,
    required this.address,
    required this.age,
    required this.dob,
    required this.cccd,
  });

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      department: json["department"] ?? "",
      role: json["role"] ?? "",
      phone: json["phone"] ?? "",
      address: json["address"] ?? "",
      age: json["age"] ?? "",
      dob: json["date_of_birth"] ?? "",
      cccd: json["cccd"] ?? "",
    );
  }
}