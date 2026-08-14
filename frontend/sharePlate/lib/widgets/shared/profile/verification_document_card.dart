import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/verification_document_model.dart';

/// Card showing one document that was submitted for verification.
/// Displays document thumbnail/icon, metadata, status badge, and view/replace actions.
class VerificationDocumentCard extends StatelessWidget {
  const VerificationDocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onChangeTap,
  });

  final VerificationDocumentModel document;
  final VoidCallback onTap;
  final VoidCallback? onChangeTap;

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final hasLocalImage = document.localFilePath != null &&
        !kIsWeb &&
        File(document.localFilePath!).existsSync() &&
        (document.type == VerificationDocumentType.image ||
            document.localFilePath!.toLowerCase().endsWith('.jpg') ||
            document.localFilePath!.toLowerCase().endsWith('.jpeg') ||
            document.localFilePath!.toLowerCase().endsWith('.png'));

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardLightBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: hasLocalImage
                    ? Image.file(
                        File(document.localFilePath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _defaultDocIcon(),
                      )
                    : _defaultDocIcon(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          document.type == VerificationDocumentType.image
                              ? Icons.image_outlined
                              : Icons.picture_as_pdf_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            document.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: status.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon, size: 12, color: status.foreground),
                              const SizedBox(width: 4),
                              Text(
                                status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: status.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (document.issuedIdNumber != null && document.issuedIdNumber!.isNotEmpty)
                          Text(
                            'ID: ${document.issuedIdNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onChangeTap != null)
                    IconButton(
                      icon: const Icon(Icons.edit_document, size: 20, color: AppColors.primaryEmerald),
                      tooltip: 'Change document',
                      onPressed: onChangeTap,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultDocIcon() {
    return Icon(
      document.type == VerificationDocumentType.pdf
          ? Icons.picture_as_pdf_rounded
          : Icons.badge_outlined,
      color: AppColors.primary,
      size: 24,
    );
  }
}
