import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/picked_location.dart';

class BusinessLocationPickerTile extends StatelessWidget {
  const BusinessLocationPickerTile({
    super.key,
    required this.location,
    required this.onTap,
  });

  final PickedLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = location != null;

    return Semantics(
      button: true,
      label: 'Pin business location on map',
      child: Material(
        color: AppColors.primaryEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryEmerald.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.primaryEmerald),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSelected
                            ? 'Business location pinned'
                            : 'Pin business location on map',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSelected
                            ? location?.address ?? ''
                            : 'Choose the exact location where food can be collected.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryEmerald,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
