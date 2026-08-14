import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, this.onTap});

  final NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.timeAgo,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full "Notifications" list, including the header row and dividers
/// between entries. Shared by every role's notification screen so the
/// layout described in the mock-up only has to be built once.
class NotificationListView extends StatelessWidget {
  const NotificationListView({super.key, required this.items});

  final List<NotificationItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'You have no notifications yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) => NotificationTile(item: items[index]),
    );
  }
}