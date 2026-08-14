import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/verification_document_model.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../../widgets/shared/profile/verification_document_card.dart';
import 'document_preview_screen.dart';

/// Lists the document(s) a business or NGO submitted as proof during
/// sign-up verification, and lets the user open each one to see it again.
///
/// Reused by both [DonorProfileScreen] ("Business documents") and
/// [RecipientProfileScreen] ("Verification documents") — only the title,
/// subtitle and document list differ between the two roles.
class VerificationDocumentsScreen extends StatelessWidget {
  const VerificationDocumentsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.documents,
  });

  final String title;
  final String subtitle;
  final List<VerificationDocumentModel> documents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SimpleAppBar(title: title),
      body: SafeArea(
        top: false,
        child: documents.isEmpty
            ? _EmptyState(subtitle: subtitle)
            : ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            for (final document in documents)
              VerificationDocumentCard(
                document: document,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(document: document),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No documents on file',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
