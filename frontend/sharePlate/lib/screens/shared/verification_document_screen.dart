import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/verification_document_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../../widgets/shared/profile/verification_document_card.dart';
import 'document_preview_screen.dart';

/// Lists the document(s) a business or NGO submitted as proof during
/// sign-up verification, and lets the user preview photos and change / replace documents.
class VerificationDocumentsScreen extends StatefulWidget {
  const VerificationDocumentsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.documents,
    this.role,
  });

  final String title;
  final String subtitle;
  final List<VerificationDocumentModel> documents;
  final UserRole? role;

  @override
  State<VerificationDocumentsScreen> createState() =>
      _VerificationDocumentsScreenState();
}

class _VerificationDocumentsScreenState
    extends State<VerificationDocumentsScreen> {
  late List<VerificationDocumentModel> _documentList;

  @override
  void initState() {
    super.initState();
    _documentList = List.from(widget.documents);
  }

  void _onDocumentUpdated(VerificationDocumentModel updatedDoc) {
    setState(() {
      final index = _documentList.indexWhere((d) => d.id == updatedDoc.id);
      if (index != -1) {
        _documentList[index] = updatedDoc;
      } else {
        _documentList.insert(0, updatedDoc);
      }
    });

    final auth = context.read<AuthProvider>();
    auth.updateVerificationDocument(updatedDoc, role: widget.role);
  }

  Future<void> _openQuickChange(VerificationDocumentModel doc) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final isPdf = picked.name.toLowerCase().endsWith('.pdf');
    final updated = doc.copyWith(
      fileName: picked.name,
      localFilePath: picked.path,
      type: isPdf ? VerificationDocumentType.pdf : VerificationDocumentType.image,
      status: VerificationDocumentStatus.pending,
      submittedOn: DateTime.now(),
      reviewNote: null,
    );

    _onDocumentUpdated(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document updated with "${picked.name}". Submitted for review!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = _documentList.isNotEmpty ? _documentList.first : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SimpleAppBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              widget.subtitle,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (doc == null)
              _EmptyState(subtitle: widget.subtitle)
            else ...[
              VerificationDocumentCard(
                document: doc,
                onChangeTap: () => _openQuickChange(doc),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DocumentPreviewScreen(
                      document: doc,
                      onDocumentUpdated: _onDocumentUpdated,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DocumentPreviewScreen(
                            document: doc,
                            onDocumentUpdated: _onDocumentUpdated,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primaryEmerald),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.visibility_outlined, color: AppColors.primaryEmerald, size: 18),
                      label: const Text(
                        'Preview Document',
                        style: TextStyle(
                          color: AppColors.primaryEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openQuickChange(doc),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primaryEmerald,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Change Document',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'No documents on file',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15),
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
