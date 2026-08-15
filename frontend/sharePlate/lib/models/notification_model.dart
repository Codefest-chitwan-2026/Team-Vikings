import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum NotificationType { success, alert, info, pickup, summary }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final NotificationType type;
  final bool isRead;
  final String? targetId;

  const NotificationItem({
    this.id = '',
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
    this.targetId,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_rounded;
      case NotificationType.alert:
        return Icons.access_time_rounded;
      case NotificationType.info:
        return Icons.receipt_long_rounded;
      case NotificationType.pickup:
        return Icons.location_on_outlined;
      case NotificationType.summary:
        return Icons.insights_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotificationType.success:
        return AppColors.primary;
      case NotificationType.alert:
        return AppColors.secondary;
      case NotificationType.info:
        return const Color(0xFF7E57C2);
      case NotificationType.pickup:
        return AppColors.primary;
      case NotificationType.summary:
        return AppColors.textSecondary;
    }
  }

  Color get iconBackground {
    switch (type) {
      case NotificationType.success:
        return AppColors.cardLightBg;
      case NotificationType.alert:
        return const Color(0xFFFDE7E0);
      case NotificationType.info:
        return const Color(0xFFEFE6F8);
      case NotificationType.pickup:
        return AppColors.cardLightBg;
      case NotificationType.summary:
        return AppColors.gray;
    }
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['notification_type'] ?? json['type'] ?? 'INFO').toString().toUpperCase();
    NotificationType nType = NotificationType.info;
    if (rawType.contains('SUCCESS') || rawType.contains('CLAIM') || rawType.contains('CONFIRM')) {
      nType = NotificationType.success;
    } else if (rawType.contains('ALERT') || rawType.contains('EXPIR') || rawType.contains('WARN')) {
      nType = NotificationType.alert;
    } else if (rawType.contains('PICKUP') || rawType.contains('ROUTE')) {
      nType = NotificationType.pickup;
    } else if (rawType.contains('SUMMARY') || rawType.contains('IMPACT')) {
      nType = NotificationType.summary;
    }

    String timeAgo = 'Just now';
    if (json['created_at'] != null) {
      try {
        final d = DateTime.parse(json['created_at'].toString());
        final diff = DateTime.now().difference(d);
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      timeAgo: timeAgo,
      type: nType,
      isRead: json['is_read'] == true,
      targetId: json['target_id']?.toString(),
    );
  }
}

class NotificationPreferencesModel {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsAlerts;
  final bool expiryReminders;
  final bool claimAlerts;
  final bool marketingUpdates;

  const NotificationPreferencesModel({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsAlerts = true,
    this.expiryReminders = true,
    this.claimAlerts = true,
    this.marketingUpdates = false,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      smsAlerts: json['sms_alerts'] ?? true,
      expiryReminders: json['expiry_reminders'] ?? true,
      claimAlerts: json['claim_alerts'] ?? true,
      marketingUpdates: json['marketing_updates'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'sms_alerts': smsAlerts,
      'expiry_reminders': expiryReminders,
      'claim_alerts': claimAlerts,
      'marketing_updates': marketingUpdates,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsAlerts,
    bool? expiryReminders,
    bool? claimAlerts,
    bool? marketingUpdates,
  }) {
    return NotificationPreferencesModel(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsAlerts: smsAlerts ?? this.smsAlerts,
      expiryReminders: expiryReminders ?? this.expiryReminders,
      claimAlerts: claimAlerts ?? this.claimAlerts,
      marketingUpdates: marketingUpdates ?? this.marketingUpdates,
    );
  }
}