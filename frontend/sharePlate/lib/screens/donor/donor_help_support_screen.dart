import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile/faq_expand_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../../widgets/shared/profile/support_contact_tile.dart';


/// Help & Support screen for the donor role.
/// TODO: wire SupportContactTile's onTap callbacks to url_launcher (tel:,
/// mailto:, or an in-app chat SDK) once one is added to pubspec.yaml.
class DonorHelpSupportScreen extends StatelessWidget {
  const DonorHelpSupportScreen({super.key});

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
              value: 'donors@shareplate.app',
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
              question: 'How do I list surplus food for donation?',
              answer:
              'Go to the Donation tab and tap Add Donation. Fill in the food '
                  'category, quantity, and pickup window, then submit — nearby '
                  'NGOs and customers will be able to see and claim it.',
            ),
            const FaqExpandTile(
              question: 'How is my listing matched with an NGO or customer?',
              answer:
              'Listings marked as donations are prioritised for verified NGOs '
                  'first. Flash-sale listings are shown to nearby customers based '
                  'on distance and how soon the pickup window closes.',
            ),
            const FaqExpandTile(
              question: 'What happens if nobody claims my listing?',
              answer:
              'The listing automatically closes once its pickup window ends. '
                  'You can always relist the same items with a new pickup window.',
            ),
            const FaqExpandTile(
              question: 'How do I update my business documents?',
              answer:
              'Open Profile → Business documents to view or replace your '
                  'verification files. Changes are reviewed before they go live.',
            ),
          ],
        ),
      ),
    );
  }
}