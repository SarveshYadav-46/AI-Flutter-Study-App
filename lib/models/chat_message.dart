/// Represents a single message in the AI chat conversation.
enum MessageRole { user, ai }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  /// True when this message represents a failed AI response.
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.isError = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAI => role == MessageRole.ai;

  /// Creates a copy with modified fields.
  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? text,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}
