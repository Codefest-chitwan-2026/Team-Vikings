import 'package:flutter/material.dart';

/// File format of an uploaded verification document, so the preview screen
/// knows whether to render an image-style or paper/PDF-style placeholder.
enum VerificationDocumentType { image, pdf }

/// Review status of a document, shown as a colored badge in the list and
/// on the preview screen.
enum VerificationDocumentStatus { verified, pending, rejected }

extension VerificationDocumentStatusX on VerificationDocumentStatus {
  String get label => switch (this) {
    VerificationDocumentStatus.verified => 'Verified',
    VerificationDocumentStatus.pending => 'Pending review',
    VerificationDocumentStatus.rejected => 'Needs re-upload',
  };

  Color get foreground => switch (this) {
    VerificationDocumentStatus.verified => const Color(0xFF2E7D32),
    VerificationDocumentStatus.pending => const Color(0xFFE65100),
    VerificationDocumentStatus.rejected => const Color(0xFFB00020),
  };

  Color get background => switch (this) {
    VerificationDocumentStatus.verified => const Color(0xFFE4F6E9),
    VerificationDocumentStatus.pending => const Color(0xFFFFF3E0),
    VerificationDocumentStatus.rejected => const Color(0xFFFCE8E8),
  };

  IconData get icon => switch (this) {
    VerificationDocumentStatus.verified => Icons.verified_rounded,
    VerificationDocumentStatus.pending => Icons.hourglass_top_rounded,
    VerificationDocumentStatus.rejected => Icons.error_outline_rounded,
  };
}

/// A single document submitted as proof during business/NGO sign-up
/// verification (e.g. business registration certificate, PAN, NGO
/// registration letter).
class VerificationDocumentModel {
  const VerificationDocumentModel({
    required this.id,
    required this.title,
    required this.fileName,
    required this.type,
    required this.status,
    required this.submittedOn,
    this.issuedIdNumber,
    this.reviewNote,
    this.previewAssetPath,
  });

  final String id;

  /// What the document is, e.g. "Business registration certificate".
  final String title;

  /// The file name as it was uploaded (what the user sees on-screen).
  final String fileName;

  final VerificationDocumentType type;
  final VerificationDocumentStatus status;

  /// Date the document was submitted for review.
  final DateTime submittedOn;

  /// Registration / PAN number printed on the document, when applicable.
  final String? issuedIdNumber;

  /// Reviewer note, mainly used when [status] is rejected.
  final String? reviewNote;

  /// Optional path to a real preview image, once documents are actually
  /// stored/served by the backend. Null falls back to a placeholder.
  final String? previewAssetPath;
}
