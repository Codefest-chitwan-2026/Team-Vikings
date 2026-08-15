import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../widgets/shared/notification_tile.dart';

/// Notifications screen shown to a donor.
class DonorNotificationsScreen extends StatefulWidget {
  const DonorNotificationsScreen({super.key});

  @override
  State<DonorNotificationsScreen> createState() =>
      _DonorNotificationsScreenState();
}

class _DonorNotificationsScreenState extends State<DonorNotificationsScreen> {
  bool _showOnlyUnread = false;

  final List<NotificationItem> _notifications = [
    const NotificationItem(
      title: 'Claim confirmed',
      message: 'Rampur Aanathalaya Org claimed your bakery box listing.',
      timeAgo: '2m',
      type: NotificationType.success,
    ),
    const NotificationItem(
      title: 'Listing expiring soon',
      message: 'Wedding catering trays auto-close in 10 minutes.',
      timeAgo: '18m',
      type: NotificationType.alert,
    ),
    const NotificationItem(
      title: 'New deal nearby',
      message: 'Cafe Norling just listed a 70% off pastry box, 0.9 km away.',
      timeAgo: '40m',
      type: NotificationType.info,
    ),
    const NotificationItem(
      title: 'Pickup completed',
      message: 'Your donation to Devghat Aanath Ashram was confirmed.',
      timeAgo: '3h',
      type: NotificationType.pickup,
    ),
    const NotificationItem(
      title: 'Weekly impact summary',
      message: "You've helped divert 42 kg of food from waste this week.",
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