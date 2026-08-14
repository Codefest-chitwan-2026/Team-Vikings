import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';
import '../shared/verification_document_screen.dart';
import 'recipient_edit_profile.dart';
import 'recipient_help_support_screen.dart';
import 'recipient_notification_settings_screen.dart';

/// Profile tab shown to a recipient (NGO).
class RecipientProfileScreen extends StatelessWidget {
  const RecipientProfileScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openVerificationDocuments(BuildContext context, AuthProvider auth) {
    final docs = auth.getDocumentsForRole(UserRole.ngo);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationDocumentsScreen(
          title: 'Verification documents',
          subtitle:
              'Documents submitted to verify your organization. Verified status enables food rescue claiming.',
          documents: docs,
          role: UserRole.ngo,
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

    final orgName = user?.organizationName != null && user!.organizationName!.isNotEmpty
        ? user.organizationName!
        : (user?.displayName.isNotEmpty == true ? user!.displayName : 'Aasha Foundation');
    final orgSubtitle = user?.email.isNotEmpty == true
        ? 'Recipient · ${user!.email}'
        : 'Recipient · NGO';
    final initials = user?.initials ?? 'AF';
    final avatarPath = user?.profileData?['avatar_path'] as String?;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          ProfileHeader(
            initials: initials,
            name: orgName,
            subtitle: orgSubtitle,
            avatarPath: avatarPath,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecipientEditProfileScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.verified_user_outlined,
            label: 'Verification documents',
            onTap: () => _openVerificationDocuments(context, authProvider),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.location_on_outlined,
            label: 'Saved addresses',
            onTap: () => _showComingSoon(context, 'Saved addresses'),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.notifications_none_rounded,
            label: 'Notification settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecipientNotificationSettingsScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecipientHelpSupportScreen()),
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