import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';
import 'consumer_help_support_screen.dart';
import 'consumer_notification_settings_screen.dart';

/// Profile tab shown to a consumer (customer).
/// TODO: replace the hard-coded name/stats with the signed-in UserModel once
/// the consumer profile API is wired up.
class ConsumerProfileScreen extends StatelessWidget {
  const ConsumerProfileScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature coming soon.')));
  }

  void _logOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const ProfileHeader(
            initials: 'RS',
            name: 'Rojina Shrestha',
            subtitle: 'Customer',
          ),
          const SizedBox(height: 20),
          const ProfileStatsBar(
            stats: [
              ProfileStat(value: '18', label: 'Orders'),
              ProfileStat(value: 'Rs 2.1k', label: 'Saved'),
              ProfileStat(value: '340', label: 'Points'),
            ],
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () => _showComingSoon(context, 'Edit profile'),
          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.location_on_outlined,
            label: 'Saved addresses',
            onTap: () => _showComingSoon(context, 'Saved addresses'),
          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.credit_card_outlined,
            label: 'Payment methods',
            onTap: () => _showComingSoon(context, 'Payment methods'),
          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConsumerNotificationSettingsScreen()),
            ),          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConsumerHelpSupportScreen()),
            ),          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.logout_rounded,
            label: 'Log out',
            isDestructive: true,
            showChevron: false,
            onTap: () => _logOut(context),
          ),
        ],
      ),
    );
  }
}