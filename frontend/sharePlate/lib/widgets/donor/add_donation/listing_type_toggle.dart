import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/donation_model.dart';

class ListingTypeToggle extends StatelessWidget {
  const ListingTypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ListingType selected;
  final ValueChanged<ListingType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Donate free',
              isSelected: selected == ListingType.donateFree,
              onTap: () => onChanged(ListingType.donateFree),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: 'Discounted sale',
              isSelected: selected == ListingType.discountedSale,
              onTap: () => onChanged(ListingType.discountedSale),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
