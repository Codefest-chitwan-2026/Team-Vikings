import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/donation_model.dart';
import '../add_donation/photo_upload_area.dart';
import 'donation_status_chip.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({
    super.key,
    required this.donation,
    required this.onActionTap,
    this.onCardTap,
  });

  final DonationItem donation;
  final ValueChanged<DonationCardAction> onActionTap;
  final VoidCallback? onCardTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Posted ${donation.postedAgo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  DonationStatusChip(status: donation.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FoodThumbnail(
                    imagePath: donation.imagePath,
                    category: donation.category,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${donation.quantity} ${donation.quantityUnit} · ${donation.servesApprox}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (donation.recipient != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.apartment, size: 14, color: AppColors.primaryEmerald),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  donation.recipient!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryEmerald,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < donation.actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        action: donation.actions[i],
                        onTap: () => onActionTap(donation.actions[i].action),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodThumbnail extends StatelessWidget {
  final String? imagePath;
  final FoodCategory category;

  const _FoodThumbnail({this.imagePath, required this.category});

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('preset:')) {
        final preset = SampleFoodPreset.presets.firstWhere(
          (p) => p.id == imagePath,
          orElse: () => SampleFoodPreset.presets.first,
        );
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: preset.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(preset.icon, color: Colors.white, size: 24),
        );
      }

      if (!kIsWeb && File(imagePath!).existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(category),
            ),
          ),
        );
      }
    }

    return _fallback(category);
  }

  Widget _fallback(FoodCategory category) {
    List<Color> colors;
    IconData icon;

    switch (category) {
      case FoodCategory.veg:
        colors = const [Color(0xFF2E7D32), Color(0xFF1B5E20)];
        icon = Icons.eco;
        break;
      case FoodCategory.nonVeg:
        colors = const [Color(0xFFE65100), Color(0xFFBF360C)];
        icon = Icons.restaurant;
        break;
      case FoodCategory.mixed:
        colors = const [Color(0xFF1565C0), Color(0xFF0D47A1)];
        icon = Icons.fastfood;
        break;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final DonationAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (action.isPrimary) {
      return SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryEmerald,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            action.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: action.isDestructive
              ? AppColors.error
              : AppColors.textPrimary,
          side: BorderSide(
            color: action.isDestructive ? AppColors.error : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          action.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: action.isDestructive
                ? AppColors.error
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
