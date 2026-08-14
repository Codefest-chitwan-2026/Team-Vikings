import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../shared/document_upload_tile.dart';

class BusinessDocumentSection extends StatelessWidget {
  const BusinessDocumentSection({
    super.key,
    required this.verificationDocumentPath,
    required this.onVerificationDocumentTap,
  });

  final String? verificationDocumentPath;
  final VoidCallback onVerificationDocumentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add one official document that verifies your business.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        DocumentUploadTile(
          title: 'Verification document',
          subtitle: 'Business registration, PAN, tax clearance, or similar proof',
          fileName: verificationDocumentPath,
          isUploaded: verificationDocumentPath != null,
          onTap: onVerificationDocumentTap,
        ),
      ],
    );
  }
}
