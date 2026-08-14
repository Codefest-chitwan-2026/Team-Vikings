import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../widgets/shared/notification_tile.dart';

/// Notifications tab shown to a recipient (NGO).
/// TODO: replace [_mockNotifications] with data fetched for the signed-in NGO.
class RecipientNotificationsScreen extends StatelessWidget {
  const RecipientNotificationsScreen({super.key});

  static const List<NotificationItem> _mockNotifications = [
    NotificationItem(
      title: 'New listing nearby',
      message: 'Chitwan Black Forest posted a free bakery box, 0.6 km away.',
      timeAgo: '5m',
      type: NotificationType.info,
    ),
    NotificationItem(
      title: 'Claim confirmed',
      message: 'Your claim on the wedding catering trays was accepted.',
      timeAgo: '22m',
      type: NotificationType.success,
    ),
    NotificationItem(
      title: 'Pickup window closing soon',
      message: 'Pickup for the rice & curry listing closes in 15 minutes.',
      timeAgo: '35m',
      type: NotificationType.alert,
    ),
    NotificationItem(
      title: 'Pickup completed',
      message: 'Your pickup from Hotel Barahi was marked as completed.',
      timeAgo: '4h',
      type: NotificationType.pickup,
    ),
    NotificationItem(
      title: 'Weekly impact summary',
      message: "Your organisation received 58 kg of food this week.",
      timeAgo: '1d',
      type: NotificationType.summary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Expanded(
            child: NotificationListView(items: _mockNotifications),
          ),
        ],
      ),
    );
  }
}