import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';
import '../../widgets/login_screen/primary_button.dart';
import 'recipient_home_screen.dart';

class ClaimSuccessScreen extends StatelessWidget {
  const ClaimSuccessScreen({super.key, required this.listing});

  final RecipientListing listing;

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RecipientHomeScreen()),
      (route) => false,
    );
  }

  void _getDirections(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${listing.pickupAddress}…'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donorShortName = listing.donorName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.primaryEmerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Claim confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$donorShortName has been notified. Please pick up the '
                '${listing.quantity} ${listing.title.toLowerCase()} within '
                '${listing.minutesLeft} minutes from ${listing.area}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                text: 'Get directions',
                onPressed: () => _getDirections(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _goHome(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryEmerald,
                    side: const BorderSide(color: AppColors.primaryEmerald),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
