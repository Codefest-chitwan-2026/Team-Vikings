import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/verification_document_model.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';

/// Shows the full preview of one verification document plus the metadata
/// a reviewer/user would want to double check (submitted date, ID number,
/// status, reviewer note).
///
/// TODO: once documents are actually uploaded to storage, swap the
/// placeholder preview for `Image.network(document.previewAssetPath)` (or a
/// PDF viewer for `VerificationDocumentType.pdf`) using the real file URL
/// returned by the backend.
class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({super.key, required this.document});

  final VerificationDocumentModel document;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final status = document.status;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SimpleAppBar(title: document.title),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _DocumentPreviewFrame(document: document),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    document.fileName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 14, color: status.foreground),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'Submitted on', value: _formatDate(document.submittedOn)),
                  if (document.issuedIdNumber != null) ...[
                    const SizedBox(height: 10),
                    _DetailRow(label: 'ID / registration number', value: document.issuedIdNumber!),
                  ],
                ],
              ),
            ),
            if (status == VerificationDocumentStatus.rejected && document.reviewNote != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warningText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        document.reviewNote!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.warningText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Replace document coming soon.')),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18, color: AppColors.textPrimary),
              label: const Text(
                'Replace document',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The document preview itself. Renders the real file once one is
/// available; falls back to a paper-style placeholder for this demo build.
class _DocumentPreviewFrame extends StatelessWidget {
  const _DocumentPreviewFrame({required this.document});

  final VerificationDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final previewPath = document.previewAssetPath;

    return AspectRatio(
      aspectRatio: document.type == VerificationDocumentType.pdf ? 3 / 4 : 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: previewPath != null
            ? Image.asset(previewPath, fit: BoxFit.cover)
            : _PlaceholderPreview(type: document.type),
      ),
    );
  }
}

class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview({required this.type});

  final VerificationDocumentType type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.cardLightBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              type == VerificationDocumentType.pdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.image_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preview unavailable',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This file will render here once document storage is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
