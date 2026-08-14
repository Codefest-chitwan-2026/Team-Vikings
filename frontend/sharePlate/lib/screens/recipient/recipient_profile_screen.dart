

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';

/// Profile tab shown to a recipient (NGO).
/// TODO: replace the hard-coded stats with the signed-in NgoModel once the
/// recipient profile API is wired up.
class RecipientProfileScreen extends StatelessWidget {
  const RecipientProfileScreen({super.key});

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
    final orgName = RecipientListingModel.organizationName;
    final initials = orgName.trim().isEmpty
        ? 'NG'
        : orgName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          ProfileHeader(
            initials: initials,
            name: orgName,
            subtitle: 'Recipient · NGO',
          ),
          const SizedBox(height: 20),
          const ProfileStatsBar(
            stats: [
              ProfileStat(value: '#12', label: 'Rank'),
              ProfileStat(value: '214', label: 'Claims'),
              ProfileStat(value: '860', label: 'Points'),
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
            label: 'Verification documents',
            onTap: () => _showComingSoon(context, 'Verification documents'),
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