import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile/faq_expand_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../../widgets/shared/profile/support_contact_tile.dart';

/// Help & Support screen for the recipient (NGO) role.
/// TODO: wire SupportContactTile's onTap callbacks to url_launcher (tel:,
/// mailto:, or an in-app chat SDK) once one is added to pubspec.yaml.
class RecipientHelpSupportScreen extends StatelessWidget {
  const RecipientHelpSupportScreen({super.key});

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SimpleAppBar(title: 'Help & support'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            const Text(
              'Get in touch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SupportContactTile(
              icon: Icons.call_outlined,
              title: 'Call support',
              value: '+977 1-4000000 · 9 AM - 7 PM',
              onTap: () => _showComingSoon(context, 'Calling support'),
            ),
            const SizedBox(height: 10),
            SupportContactTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email us',
              value: 'partners@shareplate.app',
              onTap: () => _showComingSoon(context, 'Opening email'),
            ),
            const SizedBox(height: 10),
            SupportContactTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live chat',
              value: 'Usually replies within a few minutes',
              onTap: () => _showComingSoon(context, 'Live chat'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Frequently asked questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const FaqExpandTile(
              question: 'How do I claim a listing?',
              answer:
              'Open the Browse tab, tap a listing to see its details, then tap '
                  'Claim. The donor is notified immediately and the listing is '
                  'reserved for your organization until the pickup window closes.',
            ),
            const FaqExpandTile(
              question: 'Why can\'t I see some listings?',
              answer:
              'Some donation listings are prioritised for verified NGOs only. '
                  'Make sure your organization\'s verification documents have '
                  'been approved under Profile → Verification documents.',
            ),
            const FaqExpandTile(
              question: 'What happens if I miss a pickup window?',
              answer:
              'The claim is automatically released back to the donor so other '
                  'organizations or customers can claim it instead.',
            ),
            const FaqExpandTile(
              question: 'How do I update our organization details?',
              answer:
              'Go to Profile → Edit profile to update your organization name, '
                  'type, contact details, and pickup location.',
            ),
          ],
        ),
      ),
    );
  }
}