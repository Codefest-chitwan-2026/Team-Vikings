import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';
import '../shared/verification_document_screen.dart';
import 'donor_edit_profile.dart';
import 'donor_help_support_screen.dart';
import 'donor_notification_settings_screen.dart';

/// Profile tab shown to a donor (Food Business).
class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});

  void _openBusinessDocuments(BuildContext context, AuthProvider auth) {
    final docs = auth.getDocumentsForRole(UserRole.donor);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationDocumentsScreen(
          title: 'Verification document',
          subtitle:
              'Official document submitted to verify your business. This is reviewed before your listings go live.',
          documents: docs,
          role: UserRole.donor,
        ),
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

    final bizName = user?.organizationName != null && user!.organizationName!.isNotEmpty
        ? user.organizationName!
        : (user?.displayName.isNotEmpty == true ? user!.displayName : 'Himalayan Bites Cafe');
    final bizSubtitle = user?.email.isNotEmpty == true
        ? 'Donor · ${user!.email}'
        : 'Donor · Food Business';
    final bizInitials = user?.initials ?? 'HB';
    final avatarPath = user?.profileData?['avatar_path'] as String?;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          ProfileHeader(
            initials: bizInitials,
            name: bizName,
            subtitle: bizSubtitle,
            avatarPath: avatarPath,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonorEditProfileScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.verified_user_outlined,
            label: 'Verification document',
            onTap: () => _openBusinessDocuments(context, authProvider),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonorNotificationSettingsScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonorHelpSupportScreen()),
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