import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';

/// Profile tab shown to a donor.
/// TODO: replace the hard-coded name/stats with the signed-in UserModel /
/// BusinessRegistrationModel once the donor profile API is wired up.
class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});

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
            initials: 'CB',
            name: 'Chitwan Black Forest',
            subtitle: 'Donor · Hotel & Restaurant',
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const Divider(height: 1, color: AppColors.border),
          const Divider(height: 1, color: AppColors.border),
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
            label: 'Business documents',
            onTap: () => _showComingSoon(context, 'Business documents'),
          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification settings',
            onTap: () => _showComingSoon(context, 'Notification settings'),
          ),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & support',
            onTap: () => _showComingSoon(context, 'Help & support'),
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