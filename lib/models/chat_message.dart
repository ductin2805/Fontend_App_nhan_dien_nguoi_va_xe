class ChatMessage {
  final int? id;
  final String role; // user / bot
  final String text;
  final String? source;
  final String? warning; // Thêm trường warning
  final int timestamp;

  ChatMessage({
    this.id,
    required this.role,
    required this.text,
    this.source,
    this.warning,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "role": role,
      "text": text,
      "source": source,
      "warning": warning,
      "timestamp": timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map["id"] as int?,
      role: map["role"] as String,
      text: map["text"] as String,
      source: map["source"] as String?,
      warning: map["warning"] as String?,
      timestamp: map["timestamp"] as int,
    );
  }
}
