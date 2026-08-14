import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';

class RecipientStatsBar extends StatelessWidget {
  const RecipientStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = RecipientListingModel.stats;

    return Row(
      children: [
        Expanded(
          child: _StatItem(
            value: '${stats.mealsClaimed}',
            label: 'Meals claimed',
          ),
        ),
        _divider(),
        Expanded(
          child: _StatItem(
            value: '${stats.activeListings}',
            label: 'Active listings',
          ),
        ),
        _divider(),
        Expanded(
          child: _StatItem(
            value: stats.savedOnDeals,
            label: 'Saved on deals',
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
