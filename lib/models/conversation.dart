class Conversation {
  final String id;
  final String? name;
  final String? avatarUrl;
  final bool isGroup;
  final String? lastMessage;
  final DateTime? updatedAt;
  final int? unreadCount;
  final String? memberRole;
  final bool? isOnline;
  final DateTime createdAt;
  Conversation({required this.id, this.name, this.avatarUrl, this.isGroup = false, this.lastMessage, this.updatedAt, this.unreadCount, this.memberRole, this.isOnline, required this.createdAt});

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'].toString(),
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isGroup: json['is_group'] == true,
        lastMessage: json['last_message'] as String? ?? json['lastMessage'] as String?,
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? (json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null) ?? (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : DateTime.now()),
        unreadCount: json['unread_count'] is int ? json['unread_count'] as int : (json['unreadCount'] is int ? json['unreadCount'] as int : 0),
        memberRole: json['member_role'] as String? ?? json['memberRole'] as String?,
        isOnline: json['is_online'] == true || json['isOnline'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
