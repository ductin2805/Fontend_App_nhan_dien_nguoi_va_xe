class ChatMessage {
  final int? id;
  final String role; // user / bot
  final String text;
  final String? source;
  final int timestamp;

  ChatMessage({
    this.id,
    required this.role,
    required this.text,
    this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "role": role,
      "text": text,
      "source": source,
      "timestamp": timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map["id"] as int?,
      role: map["role"] as String,
      text: map["text"] as String,
      source: map["source"] as String?,
      timestamp: map["timestamp"] as int,
    );
  }
}