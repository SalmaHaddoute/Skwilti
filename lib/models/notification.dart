import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum NotificationType {
  room_created,
  qcm_completed,
  new_student,
  achievement,
  other
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.other,
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.room_created:
        return LucideIcons.zap;
      case NotificationType.qcm_completed:
        return LucideIcons.fileCheck;
      case NotificationType.new_student:
        return LucideIcons.userPlus;
      case NotificationType.achievement:
        return LucideIcons.award;
      default:
        return LucideIcons.bell;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.room_created:
        return Colors.orange;
      case NotificationType.qcm_completed:
        return Colors.green;
      case NotificationType.new_student:
        return Colors.blue;
      case NotificationType.achievement:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
