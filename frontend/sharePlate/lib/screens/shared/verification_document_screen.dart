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
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    await context.read<AuthProvider>().fetchVerificationDocuments();
  }

  Future<void> _onDocumentUpdated(VerificationDocumentModel updatedDoc) async {
    final auth = context.read<AuthProvider>();
    setState(() => _isUploading = true);
    try {
      await auth.updateVerificationDocument(updatedDoc, role: widget.role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${updatedDoc.title}" submitted for verification!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update document: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadDocument({VerificationDocumentModel? existingDoc}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final isPdf = picked.name.toLowerCase().endsWith('.pdf');

    if (existingDoc != null) {
      final updated = existingDoc.copyWith(
        fileName: picked.name,
        localFilePath: picked.path,
        type: isPdf ? VerificationDocumentType.pdf : VerificationDocumentType.image,
        status: VerificationDocumentStatus.pending,
        submittedOn: DateTime.now(),
        reviewNote: null,
      );
      await _onDocumentUpdated(updated);
    } else {
      final newDoc = VerificationDocumentModel(
        id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
        title: isPdf ? 'Registration Certificate (PDF)' : 'Official License / ID',
        fileName: picked.name,
        localFilePath: picked.path,
        type: isPdf ? VerificationDocumentType.pdf : VerificationDocumentType.image,
        status: VerificationDocumentStatus.pending,
        submittedOn: DateTime.now(),
        issuedIdNumber: 'NGO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        issuerAuthority: 'Social Welfare Council / Gov Authority',
      );
      setState(() => _isUploading = true);
      try {
        await context.read<AuthProvider>().addVerificationDocument(newDoc, role: widget.role);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document "${picked.name}" uploaded successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final targetRole = widget.role ?? auth.currentUser?.role ?? UserRole.ngo;
    final currentDocs = auth.getDocumentsForRole(targetRole);
    final displayDocs = currentDocs.isNotEmpty ? currentDocs : widget.documents;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SimpleAppBar(title: widget.title),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryEmerald,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                widget.subtitle,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 16),

              if (_isUploading)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Uploading and syncing document with server...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryEmerald),
                        ),
                      ),
                    ],
                  ),
                ),

              if (displayDocs.isEmpty)
                _EmptyState(
                  subtitle: widget.subtitle,
                  onUploadTap: () => _pickAndUploadDocument(),
                )
              else ...[
                for (int i = 0; i < displayDocs.length; i++) ...[
                  VerificationDocumentCard(
                    document: displayDocs[i],
                    onChangeTap: () => _pickAndUploadDocument(existingDoc: displayDocs[i]),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DocumentPreviewScreen(
                          document: displayDocs[i],
                          onDocumentUpdated: _onDocumentUpdated,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DocumentPreviewScreen(
                              document: displayDocs.first,
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
                          'Preview',
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
                        onPressed: () => _pickAndUploadDocument(existingDoc: displayDocs.first),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.subtitle, required this.onUploadTap});

  final String subtitle;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onUploadTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Upload Verification Document',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
