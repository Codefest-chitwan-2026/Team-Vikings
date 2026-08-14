import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../widgets/shared/notification_tile.dart';

/// Notifications tab shown to a donor.
/// TODO: replace [_mockNotifications] with data fetched for the signed-in donor.
class DonorNotificationsScreen extends StatelessWidget {
  const DonorNotificationsScreen({super.key});

  static const List<NotificationItem> _mockNotifications = [
    NotificationItem(
      title: 'Claim confirmed',
      message: 'Rampur Aanathalaya Org claimed your bakery box listing.',
      timeAgo: '2m',
      type: NotificationType.success,
    ),
    NotificationItem(
      title: 'Listing expiring soon',
      message: 'Wedding catering trays auto-close in 10 minutes.',
      timeAgo: '18m',
      type: NotificationType.alert,
    ),
    NotificationItem(
      title: 'New deal nearby',
      message: 'Cafe Norling just listed a 70% off pastry box, 0.9 km away.',
      timeAgo: '40m',
      type: NotificationType.info,
    ),
    NotificationItem(
      title: 'Pickup completed',
      message: 'Your donation to Devghat Aanath Ashram was confirmed.',
      timeAgo: '3h',
      type: NotificationType.pickup,
    ),
    NotificationItem(
      title: 'Weekly impact summary',
      message: "You've helped divert 42 kg of food from waste this week.",
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