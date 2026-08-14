import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/recipient/consumer_bottom_navigation.dart';
import 'consumer_notifications_screen.dart';
import 'consumer_profile_screen.dart';

/// Home shell for the consumer (customer) role.
/// The Home and Deals tabs are placeholders — wire them up the same way
/// DonorHomeScreen / RecipientHomeScreen wire their tabs once the browse/deals
/// screen for customers is designed. Notifications and Profile are fully wired.
class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          const _ConsumerPlaceholderTab(
            icon: Icons.home_outlined,
            title: 'Home',
            subtitle: 'Discover discounted meals and nearby deals.',
          ),
          const _ConsumerPlaceholderTab(
            icon: Icons.local_offer_outlined,
            title: 'Deals',
            subtitle: 'Browse every flash-sale listing near you.',
          ),
          const ConsumerNotificationsScreen(),
          const ConsumerProfileScreen(),
        ],
      ),
      bottomNavigationBar: ConsumerBottomNavigation(
        currentIndex: _selectedTab,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _ConsumerPlaceholderTab extends StatelessWidget {
  const _ConsumerPlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}