import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DocumentUploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? fileName;
  final bool isUploaded;
  final VoidCallback onTap;

  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.fileName,
    this.isUploaded = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? AppColors.primary : AppColors.border,
            width: isUploaded ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isUploaded
                    ? AppColors.cardLightBg
                    : const Color(0xFFF2F4F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isUploaded ? Icons.insert_drive_file_rounded : Icons.add_rounded,
                color: isUploaded ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded ? (fileName ?? 'File uploaded') : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUploaded ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploaded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardLightBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}