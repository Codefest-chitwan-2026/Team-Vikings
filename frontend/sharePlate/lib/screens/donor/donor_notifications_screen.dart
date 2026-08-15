import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/shared/notification_tile.dart';

class DonorNotificationsScreen extends StatefulWidget {
  const DonorNotificationsScreen({super.key});

  @override
  State<DonorNotificationsScreen> createState() =>
      _DonorNotificationsScreenState();
}

class _DonorNotificationsScreenState extends State<DonorNotificationsScreen> {
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetch();
    });
  }

  Future<void> _fetch() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      await context.read<NotificationProvider>().fetchNotifications(token: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final token = auth.currentUser?.token;

    final notifications = notifProvider.notifications;
    final unreadCount = notifProvider.unreadCount;

    final displayedNotifications = _showOnlyUnread
        ? notifications.where((n) => !n.isRead).toList()
        : notifications;

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
              if (token != null && token.isNotEmpty) {
                notifProvider.markAllAsRead(token: token);
              }
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
        child: RefreshIndicator(
          onRefresh: _fetch,
          color: AppColors.primaryEmerald,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All (${notifications.length})'),
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
                      label: Text('Unread ($unreadCount)'),
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
                  items: displayedNotifications,
                  onItemTap: (item) {
                    if (token != null && token.isNotEmpty && item.id.isNotEmpty) {
                      notifProvider.markAsRead(token: token, id: item.id);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}