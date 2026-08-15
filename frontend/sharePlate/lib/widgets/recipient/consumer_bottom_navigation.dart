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
      _NavigationDestination(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavigationDestination(
        icon: Icons.volunteer_activism_outlined,
        activeIcon: Icons.volunteer_activism_rounded,
        label: 'Sponsor Food',
      ),
      _NavigationDestination(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Orders',
      ),
      _NavigationDestination(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
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
                      isSelected ? destination.activeIcon : destination.icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
  const _NavigationDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}