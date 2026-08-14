import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../widgets/shared/notification_tile.dart';

/// Notifications tab shown to a consumer (customer).
/// TODO: replace [_mockNotifications] with data fetched for the signed-in customer.
class ConsumerNotificationsScreen extends StatelessWidget {
  const ConsumerNotificationsScreen({super.key});

  static const List<NotificationItem> _mockNotifications = [
    NotificationItem(
      title: 'Order confirmed',
      message: 'Your flash-sale pastry box from Cafe Norling is confirmed.',
      timeAgo: '3m',
      type: NotificationType.success,
    ),
    NotificationItem(
      title: 'Pickup window closing soon',
      message: 'Pick up your rice & curry box in the next 10 minutes.',
      timeAgo: '12m',
      type: NotificationType.alert,
    ),
    NotificationItem(
      title: 'New deal nearby',
      message: 'Hotel Barahi just listed a 60% off dinner box, 0.7 km away.',
      timeAgo: '30m',
      type: NotificationType.info,
    ),
    NotificationItem(
      title: 'Order picked up',
      message: 'Your order from Chitwan Black Forest was marked collected.',
      timeAgo: '2h',
      type: NotificationType.pickup,
    ),
    NotificationItem(
      title: 'Weekly savings summary',
      message: "You've saved Rs 850 and rescued 6 kg of food this week.",
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