import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/donation_model.dart';

class FoodCategorySelector extends StatelessWidget {
  const FoodCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FoodCategory selected;
  final ValueChanged<FoodCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FoodCategory.values.map((category) {
        final isSelected = category == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: category != FoodCategory.mixed ? 10 : 0,
            ),
            child: _CategoryCard(
              category: category,
              isSelected: isSelected,
              onTap: () => onChanged(category),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final FoodCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label => switch (category) {
        FoodCategory.veg => 'Veg',
        FoodCategory.nonVeg => 'Non-veg',
        FoodCategory.mixed => 'Mixed',
      };

  IconData get _icon => switch (category) {
        FoodCategory.veg => Icons.radio_button_unchecked,
        FoodCategory.nonVeg => Icons.cancel_outlined,
        FoodCategory.mixed => Icons.ramen_dining_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF3E5F5) : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF9C27B0) : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                _icon,
                size: 22,
                color: isSelected ? const Color(0xFF9C27B0) : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF9C27B0) : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
