import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Visual category for a notification. Drives the icon + colour used by
/// [NotificationTile] so every role (donor / recipient / consumer) renders
/// the same look-and-feel described in the Notifications mock-up.
enum NotificationType { success, alert, info, pickup, summary }

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
  });

  final String title;
  final String message;
  final String timeAgo;
  final NotificationType type;

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
}