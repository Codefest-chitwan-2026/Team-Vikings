import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../widgets/shared/notification_tile.dart';

/// Notifications screen shown to a consumer (customer).
class ConsumerNotificationsScreen extends StatefulWidget {
  const ConsumerNotificationsScreen({super.key});

  @override
  State<ConsumerNotificationsScreen> createState() =>
      _ConsumerNotificationsScreenState();
}

class _ConsumerNotificationsScreenState
    extends State<ConsumerNotificationsScreen> {
  bool _showOnlyUnread = false;

  final List<NotificationItem> _notifications = [
    const NotificationItem(
      title: 'Order confirmed',
      message: 'Your flash-sale pastry box from Cafe Norling is confirmed.',
      timeAgo: '3m',
      type: NotificationType.success,
    ),
    const NotificationItem(
      title: 'Pickup window closing soon',
      message: 'Pick up your rice & curry box in the next 10 minutes.',
      timeAgo: '12m',
      type: NotificationType.alert,
    ),
    const NotificationItem(
      title: 'New deal nearby',
      message: 'Hotel Barahi just listed a 60% off dinner box, 0.7 km away.',
      timeAgo: '30m',
      type: NotificationType.info,
    ),
    const NotificationItem(
      title: 'Order picked up',
      message: 'Your order from Chitwan Black Forest was marked collected.',
      timeAgo: '2h',
      type: NotificationType.pickup,
    ),
    const NotificationItem(
      title: 'Weekly savings summary',
      message: "You've saved Rs 850 and rescued 6 kg of food this week.",
      timeAgo: '1d',
      type: NotificationType.summary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded,
                color: AppColors.primaryEmerald),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All (${_notifications.length})'),
                    selected: !_showOnlyUnread,
                    onSelected: (val) =>
                        setState(() => _showOnlyUnread = false),
                    selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: !_showOnlyUnread
                          ? AppColors.primaryEmerald
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread (2)'),
                    selected: _showOnlyUnread,
                    onSelected: (val) =>
                        setState(() => _showOnlyUnread = true),
                    selectedColor: AppColors.primaryEmerald.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showOnlyUnread
                          ? AppColors.primaryEmerald
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListView(
                items: _showOnlyUnread
                    ? _notifications.take(2).toList()
                    : _notifications,
              ),
            ),
          ],
        ),
      ),
    );
  }
}