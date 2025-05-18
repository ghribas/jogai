class Message {
  final int id;
  final int chatId;
  final String sender; // 'user' or 'gemini'
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'] ?? 0, // Supondo que chat_id pode não vir em todos os contextos, ou usar um valor padrão
      sender: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_id': chatId,
    'sender': sender,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };
} 