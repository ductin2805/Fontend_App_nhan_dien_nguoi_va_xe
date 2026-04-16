class FaceRegisterResponse {
  final String personId;
  final String name;
  final String personCode;
  final bool registered;
  final List<dynamic> bbox;
  final int samples;
  final String backend;
  final String imageBase64;
  final String plateNumber;
  final String vehiclePlates;
  FaceRegisterResponse({
    required this.personId,
    required this.name,
    required this.personCode,
    required this.registered,
    required this.bbox,
    required this.samples,
    required this.backend,
    required this.imageBase64,
    required this.plateNumber,
    required this.vehiclePlates,
  });

  factory FaceRegisterResponse.fromJson(Map<String, dynamic> json) {
    return FaceRegisterResponse(
      personId: json["person_id"] ?? "",
      name: json["name"] ?? "",
      personCode: json["person_code"] ?? "",
      registered: json["registered"] ?? false,
      bbox: json["bbox"] ?? [],
      samples: json["samples"] ?? 0,
      backend: json["embedding_backend"] ?? "",
      imageBase64: json["annotated_image"] ?? "",
      plateNumber: json["plate_number"] ?? "",
      vehiclePlates: json["vehicle_plates"] ?? "",
    );
  }
}