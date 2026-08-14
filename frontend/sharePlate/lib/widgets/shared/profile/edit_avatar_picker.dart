import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Circular initials/photo avatar with a camera "edit" badge, shown at the top of
/// every role's Edit Profile screen.
class EditAvatarPicker extends StatelessWidget {
  const EditAvatarPicker({
    super.key,
    required this.initials,
    required this.onTap,
    this.imagePath,
  });

  final String initials;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final isLocalFile = hasImage && !kIsWeb && File(imagePath!).existsSync();

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.cardLightBg,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: isLocalFile
                    ? Image.file(
                        File(imagePath!),
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _initialsWidget(),
                      )
                    : _initialsWidget(),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryEmerald,
        ),
      ),
    );
  }
}