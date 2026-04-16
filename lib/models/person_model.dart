class Person {
  final String personId;
  final String name;
  final String personCode;
  final PersonInfo info;
  final String imagePath;
  final double createdAt;

  Person({
    required this.personId,
    required this.name,
    required this.personCode,
    required this.info,
    required this.imagePath,
    required this.createdAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      personId: json["person_id"],
      name: json["name"],
      personCode: json["person_code"],
      info: PersonInfo.fromJson(json["info"] ?? {}),
      imagePath: json["registration_image_path"] ?? "",
      createdAt: json["created_at"] ?? 0,
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
  final String plateNumber;
  final String vehiclePlates;
  PersonInfo({
    required this.department,
    required this.role,
    required this.phone,
    required this.address,
    required this.age,
    required this.dob,
    required this.cccd,
    required this.plateNumber,
    required this.vehiclePlates,
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
      plateNumber: json["plate_number"] ?? "",
      vehiclePlates: json["vehicle_plates"] ?? "",
    );
  }
}