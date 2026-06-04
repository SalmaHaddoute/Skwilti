class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['id'].toString(),
        conversationId: json['conversation_id'].toString(),
        senderId: json['sender_id'].toString(),
        content: json['content'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>?,
        isRead: json['is_read'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
