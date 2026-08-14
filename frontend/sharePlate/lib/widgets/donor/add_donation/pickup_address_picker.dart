import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/picked_location.dart';

class PickupAddressPicker extends StatelessWidget {
  const PickupAddressPicker({
    super.key,
    required this.location,
    required this.onTap,
    this.errorText,
  });

  final PickedLocation? location;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final isSelected = location != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'Select pickup address on map',
          child: Material(
            color: isSelected
                ? AppColors.surface
                : AppColors.primaryEmerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: errorText != null
                        ? AppColors.error
                        : isSelected
                            ? AppColors.border
                            : AppColors.primaryEmerald.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.location_on_outlined : Icons.map_outlined,
                      color: AppColors.primaryEmerald,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSelected
                                ? 'Pickup location selected'
                                : 'Select pickup address on map',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.primaryEmerald,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelected
                                ? location!.address
                                : 'Tap to pin where food can be collected.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.textSecondary
                                  : AppColors.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.edit_location_alt_outlined
                          : Icons.chevron_right_rounded,
                      color: AppColors.primaryEmerald,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
