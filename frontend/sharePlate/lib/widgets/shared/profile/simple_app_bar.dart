import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A plain white app bar with a back arrow and bold title, matching the
/// style already used by BusinessSignUpScreen. Factored out so every
/// "detail"-style screen (edit profile, saved addresses, etc.) shares one
/// implementation instead of re-declaring the same AppBar each time.
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.charcoal,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}