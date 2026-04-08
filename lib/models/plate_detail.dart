class PlateDetail {
  final String text;
  final double conf;

  PlateDetail({
    required this.text,
    required this.conf,
  });

  factory PlateDetail.fromJson(Map<String, dynamic> json) {
    return PlateDetail(
      text: json['text'],
      conf: (json['conf'] as num).toDouble(),
    );
  }
}