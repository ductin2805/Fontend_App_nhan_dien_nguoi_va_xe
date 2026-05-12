class ChatResponse {
  final String reply;
  final String source;
  final bool cached;
  final String? error;
  final int? statusCode;
  final String? details;
  final String? warning;
  final String? scopeLabel;

  ChatResponse({
    required this.reply,
    required this.source,
    required this.cached,
    this.error,
    this.statusCode,
    this.details,
    this.warning,
    this.scopeLabel,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? "",
      source: json['source'] ?? "unknown",
      cached: json['cached'] ?? false,
      error: json['error'],
      statusCode: json['status_code'],
      details: json['details'],
      warning: json['warning'],
      scopeLabel: json['scope_label'],
    );
  }
}
