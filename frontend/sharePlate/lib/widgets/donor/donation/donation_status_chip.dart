import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/donation_model.dart';

class DonationStatusChip extends StatelessWidget {
  const DonationStatusChip({super.key, required this.status});

  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      DonationStatus.awaitingClaim => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          'Awaiting claim',
        ),
      DonationStatus.ngoEnRoute => (
          const Color(0xFFE3F2FD),
          const Color(0xFF0288D1),
          'NGO en route',
        ),
      DonationStatus.completed => (
          const Color(0xFFE4F6E9),
          AppColors.primary,
          'Completed',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
