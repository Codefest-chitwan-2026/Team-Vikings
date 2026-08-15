import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/recipient/consumer_bottom_navigation.dart';
import 'consumer_deals_tab.dart';
import 'consumer_orders_screen.dart';
import 'consumer_profile_screen.dart';
import 'consumer_sponsor_charity_screen.dart';

/// Home shell for the consumer (customer) role.
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
          ConsumerDealsTab(onNavigateToSponsor: () => _onTabSelected(1)),
          const ConsumerSponsorCharityScreen(),
          const ConsumerOrdersScreen(),
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