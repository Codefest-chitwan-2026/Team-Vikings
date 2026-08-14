import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile/faq_expand_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../../widgets/shared/profile/support_contact_tile.dart';


/// Help & Support screen for the consumer (customer) role.
/// TODO: wire SupportContactTile's onTap callbacks to url_launcher (tel:,
/// mailto:, or an in-app chat SDK) once one is added to pubspec.yaml.
class ConsumerHelpSupportScreen extends StatelessWidget {
  const ConsumerHelpSupportScreen({super.key});

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
              value: 'support@shareplate.app',
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
              question: 'How do I order a flash-sale box?',
              answer:
              'Browse listings on the Deals tab, tap one you like, and confirm '
                  'your order. You\'ll get a pickup window and the seller\'s address.',
            ),
            const FaqExpandTile(
              question: 'What if I can\'t make it to the pickup window?',
              answer:
              'Cancel the order from Notifications as early as possible so the '
                  'listing can be released to someone else nearby.',
            ),
            const FaqExpandTile(
              question: 'How do I pay for an order?',
              answer:
              'Payment methods can be managed from Profile → Payment methods. '
                  'You\'ll choose how to pay before confirming an order.',
            ),
            const FaqExpandTile(
              question: 'Is the food safe to eat?',
              answer:
              'Every listing includes a pickup window set by the seller so food '
                  'is collected while still fresh. Always check the listing details '
                  'for any specific storage or reheating notes.',
            ),
          ],
        ),
      ),
    );
  }
}