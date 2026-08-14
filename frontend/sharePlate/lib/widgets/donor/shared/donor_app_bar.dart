import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class DonorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DonorAppBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: AppColors.surface,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onBack,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
              ),
            ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
