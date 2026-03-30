import 'package:neznakomets/models/message.dart';

enum MessageRole { user, ai }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
    this.isTyping = false,
  });

  final String text;
  final MessageRole role;
  final DateTime timestamp;
  final bool isTyping;

  factory ChatMessage.fromMessage(Message m) {
    return ChatMessage(
      text: m.text,
      role: m.isUser ? MessageRole.user : MessageRole.ai,
      timestamp: m.timestamp,
    );
  }

  factory ChatMessage.typing() {
    return ChatMessage(
      text: '',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isTyping: true,
    );
  }
}
