class ChatResponse {
  final String reply;
  final String source;
  final bool cached;
  final String? error;
  final int? statusCode;
  final String? details;

  ChatResponse({
    required this.reply,
    required this.source,
    required this.cached,
    this.error,
    this.statusCode,
    this.details,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? "",
      source: json['source'] ?? "",
      cached: json['cached'] ?? false,
      error: json['error'],
      statusCode: json['status_code'],
      details: json['details'],
    );
  }
}