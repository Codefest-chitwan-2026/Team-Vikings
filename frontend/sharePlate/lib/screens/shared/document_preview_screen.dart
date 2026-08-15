import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/verification_document_model.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';

/// Shows the full visual preview of one verification document (with photo/certificate UI),
/// metadata, and a full feature to change / replace the verification document.
class DocumentPreviewScreen extends StatefulWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.document,
    this.onDocumentUpdated,
  });

  final VerificationDocumentModel document;
  final ValueChanged<VerificationDocumentModel>? onDocumentUpdated;

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  late VerificationDocumentModel _currentDocument;
  bool _isReplacing = false;

  @override
  void initState() {
    super.initState();
    _currentDocument = widget.document;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickReplacementDocument() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Replace Verification Document',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload a clear photo or PDF scan of your official document.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryEmerald),
                ),
                title: const Text('Choose Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('PNG, JPG, or JPEG image', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _executeFilePick(['jpg', 'jpeg', 'png'], VerificationDocumentType.image);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFE65100)),
                ),
                title: const Text('Upload PDF Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Official PDF registration file', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _executeFilePick(['pdf'], VerificationDocumentType.pdf);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeFilePick(List<String> extensions, VerificationDocumentType docType) async {
    try {
      setState(() => _isReplacing = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        final updated = _currentDocument.copyWith(
          fileName: pickedFile.name,
          localFilePath: pickedFile.path,
          type: docType,
          status: VerificationDocumentStatus.pending,
          submittedOn: DateTime.now(),
          reviewNote: null,
        );

        setState(() {
          _currentDocument = updated;
        });

        widget.onDocumentUpdated?.call(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Replaced with "${pickedFile.name}". Submitted for review!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select file. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReplacing = false);
      }
    }
  }

  void _openFullScreenPhoto(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(document: _currentDocument),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _currentDocument.status;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: SimpleAppBar(title: _currentDocument.title),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Document Photo Frame
            GestureDetector(
              onTap: () => _openFullScreenPhoto(context),
              child: Stack(
                children: [
                  _DocumentVisualCard(document: _currentDocument),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tap to Zoom',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Document Info Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentDocument.fileName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentDocument.issuerAuthority ?? 'Official Verification Record',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.background,
                    borderRadius: BorderRadius.circular(8),
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

            // Metadata Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _DetailRow(label: 'Submitted on', value: _formatDate(_currentDocument.submittedOn)),
                  if (_currentDocument.issuedIdNumber != null) ...[
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Registration / PAN', value: _currentDocument.issuedIdNumber!),
                  ],
                  if (_currentDocument.issuerAuthority != null) ...[
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Issuing authority', value: _currentDocument.issuerAuthority!),
                  ],
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Document format',
                    value: _currentDocument.type == VerificationDocumentType.pdf
                        ? 'PDF Digital Document'
                        : 'Scanned Image Photo',
                  ),
                ],
              ),
            ),

            if (status == VerificationDocumentStatus.rejected && _currentDocument.reviewNote != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warningText),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentDocument.reviewNote!,
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

            const SizedBox(height: 24),

            // Change / Replace Document Button
            ElevatedButton.icon(
              onPressed: _isReplacing ? null : _pickReplacementDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isReplacing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 20),
              label: Text(
                _isReplacing ? 'Updating document...' : 'Change / Replace Document',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          width: 135,
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

/// Visual Document Certificate / Photo Card
class _DocumentVisualCard extends StatelessWidget {
  const _DocumentVisualCard({required this.document});

  final VerificationDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = document.localFilePath != null &&
        !kIsWeb &&
        File(document.localFilePath!).existsSync() &&
        (document.type == VerificationDocumentType.image ||
            document.localFilePath!.toLowerCase().endsWith('.jpg') ||
            document.localFilePath!.toLowerCase().endsWith('.jpeg') ||
            document.localFilePath!.toLowerCase().endsWith('.png'));

    final hasRemoteImage = document.photoUrl != null &&
        document.photoUrl!.isNotEmpty &&
        (document.type == VerificationDocumentType.image ||
            document.photoUrl!.toLowerCase().endsWith('.jpg') ||
            document.photoUrl!.toLowerCase().endsWith('.jpeg') ||
            document.photoUrl!.toLowerCase().endsWith('.png'));

    if (hasLocalImage) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: const Color(0xFFF0F4F8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(document.localFilePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _OfficialCertificateCard(document: document),
        ),
      );
    } else if (hasRemoteImage) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: const Color(0xFFF0F4F8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          document.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _OfficialCertificateCard(document: document),
        ),
      );
    }

    return _OfficialCertificateCard(document: document);
  }
}

/// Official Credential Certificate Representation with security seals, PAN watermark, and details
class _OfficialCertificateCard extends StatelessWidget {
  const _OfficialCertificateCard({required this.document});

  final VerificationDocumentModel document;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB0BEC5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Emblems
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_outlined, color: AppColors.primaryEmerald, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GOVERNMENT VERIFIED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      Text(
                        document.issuerAuthority ?? 'National Registration Authority',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primaryEmerald),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.primaryEmerald),
                    SizedBox(width: 4),
                    Text(
                      'SEALED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFCFD8DC)),
          const SizedBox(height: 14),

          // Certificate Body
          Text(
            document.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Registration / ID: ${document.issuedIdNumber ?? "601234567"}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Uploaded File: ${document.fileName}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Stamp & QR indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFB0BEC5)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 28, color: AppColors.charcoal),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIGITAL SCAN ID',
                        style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'AUTH-NP-2026',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DOCUMENT ON FILE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full screen photo zoom viewer
class _FullScreenPhotoViewer extends StatelessWidget {
  const _FullScreenPhotoViewer({required this.document});

  final VerificationDocumentModel document;

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = document.localFilePath != null &&
        !kIsWeb &&
        File(document.localFilePath!).existsSync() &&
        (document.type == VerificationDocumentType.image ||
            document.localFilePath!.toLowerCase().endsWith('.jpg') ||
            document.localFilePath!.toLowerCase().endsWith('.jpeg') ||
            document.localFilePath!.toLowerCase().endsWith('.png'));

    final hasRemoteImage = document.photoUrl != null &&
        document.photoUrl!.isNotEmpty &&
        (document.type == VerificationDocumentType.image ||
            document.photoUrl!.toLowerCase().endsWith('.jpg') ||
            document.photoUrl!.toLowerCase().endsWith('.jpeg') ||
            document.photoUrl!.toLowerCase().endsWith('.png'));

    Widget viewerContent;
    if (hasLocalImage) {
      viewerContent = Image.file(File(document.localFilePath!));
    } else if (hasRemoteImage) {
      viewerContent = Image.network(document.photoUrl!);
    } else {
      viewerContent = Padding(
        padding: const EdgeInsets.all(20),
        child: _OfficialCertificateCard(document: document),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          document.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: viewerContent,
        ),
      ),
    );
  }
}
