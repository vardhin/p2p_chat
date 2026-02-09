class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.status = MessageStatus.sent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'sender_name': senderName,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'is_read': isRead,
    'status': status.toString(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    conversationId: json['conversation_id'],
    senderId: json['sender_id'],
    senderName: json['sender_name'],
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['is_read'] ?? false,
    status: MessageStatus.values.firstWhere(
      (s) => s.toString() == json['status'],
      orElse: () => MessageStatus.sent,
    ),
  );

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}
