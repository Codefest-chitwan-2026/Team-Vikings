import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';
import 'consumer_edit_profile.dart';
import 'consumer_help_support_screen.dart';
import 'consumer_notification_settings_screen.dart';

/// Profile tab shown to a consumer (customer).
class ConsumerProfileScreen extends StatelessWidget {
  const ConsumerProfileScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final name = user != null && user.displayName.isNotEmpty
        ? user.displayName
        : (user?.email ?? 'SharePlate Member');
    final subtitle = user?.email.isNotEmpty == true
        ? 'Customer · ${user!.email}'
        : 'Customer · SharePlate Member';
    final initials = user?.initials ?? 'SP';
    final avatarPath = user?.profileData?['avatar_path'] as String?;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          ProfileHeader(
            initials: initials,
            name: name,
            subtitle: subtitle,
            avatarPath: avatarPath,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConsumerEditProfileScreen()),
            ),
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
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConsumerHelpSupportScreen()),
            ),
          ),
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