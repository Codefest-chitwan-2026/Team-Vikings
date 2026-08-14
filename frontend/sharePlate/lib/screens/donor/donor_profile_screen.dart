import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/verification_document_model.dart';
import '../../widgets/shared/profile_widgets.dart';
import '../shared/login_screen.dart';
import '../shared/verification_document_screen.dart';
import 'donor_edit_profile.dart';
import 'donor_help_support_screen.dart';
import 'donor_notification_settings_screen.dart';

/// Profile tab shown to a donor.
/// TODO: replace the hard-coded name/stats with the signed-in UserModel /
/// BusinessRegistrationModel once the donor profile API is wired up.
class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});


  // TODO: replace with the documents the signed-in BusinessRegistrationModel
  // actually submitted once the profile/document API is wired up.
  static final List<VerificationDocumentModel> _businessDocuments = [
    VerificationDocumentModel(
      id: 'biz-reg-doc',
      title: 'Business registration certificate',
      fileName: 'business_registration.pdf',
      type: VerificationDocumentType.pdf,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 11, 3),
      issuedIdNumber: '601234567',
    ),
  ];

  void _openBusinessDocuments(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationDocumentsScreen(
          title: 'Business documents',
          subtitle:
          'Documents you submitted to verify Chitwan Black Forest. These are reviewed before your listings go live.',
          documents: _businessDocuments,
        ),
      ),
    );
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
          const Divider(height: 1, color: Colors.black38),
          const Divider(height: 1, color: Colors.black38),
          const Divider(height: 1, color: Colors.black38),
          const Divider(height: 1, color: Colors.black38),

          ProfileMenuTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DonorEditProfileScreen()),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const Divider(height: 1, color: AppColors.border),
          ProfileMenuTile(
            icon: Icons.credit_card_outlined,
            label: 'Business documents',
            onTap: () => _openBusinessDocuments(context),
          ),
          const Divider(height: 1, color: AppColors.border),
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