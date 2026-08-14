import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ConsumerBottomNavigation extends StatelessWidget {
  const ConsumerBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      _NavigationDestination(icon: Icons.home_outlined, label: 'Home'),
      _NavigationDestination(icon: Icons.local_offer_outlined, label: 'Deals'),
      _NavigationDestination(
        icon: Icons.notifications_none_rounded,
        label: 'Notification',
      ),
      _NavigationDestination(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: List.generate(destinations.length, (index) {
            final destination = destinations[index];
            final isSelected = index == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      destination.icon,
                      size: 20,
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isSelected
                            ? AppColors.primaryEmerald
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavigationDestination {
  const _NavigationDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}