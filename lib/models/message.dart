class Message {
  const Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
