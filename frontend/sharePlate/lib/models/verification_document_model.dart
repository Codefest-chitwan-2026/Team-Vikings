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
    this.localFilePath,
    this.photoUrl,
    this.issuerAuthority,
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

  /// Optional path to a bundled preview asset.
  final String? previewAssetPath;

  /// Optional path to a picked local file on the device filesystem.
  final String? localFilePath;

  /// Optional remote URL for hosted document photos.
  final String? photoUrl;

  /// Issuing body e.g. "Government of Nepal · Company Registrar's Office"
  final String? issuerAuthority;

  VerificationDocumentModel copyWith({
    String? id,
    String? title,
    String? fileName,
    VerificationDocumentType? type,
    VerificationDocumentStatus? status,
    DateTime? submittedOn,
    String? issuedIdNumber,
    String? reviewNote,
    String? previewAssetPath,
    String? localFilePath,
    String? photoUrl,
    String? issuerAuthority,
  }) {
    return VerificationDocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      status: status ?? this.status,
      submittedOn: submittedOn ?? this.submittedOn,
      issuedIdNumber: issuedIdNumber ?? this.issuedIdNumber,
      reviewNote: reviewNote ?? this.reviewNote,
      previewAssetPath: previewAssetPath ?? this.previewAssetPath,
      localFilePath: localFilePath ?? this.localFilePath,
      photoUrl: photoUrl ?? this.photoUrl,
      issuerAuthority: issuerAuthority ?? this.issuerAuthority,
    );
  }

  static List<VerificationDocumentModel> defaultBusinessDocuments() => [
    VerificationDocumentModel(
      id: 'biz-reg-doc-1',
      title: 'Business Registration Certificate',
      fileName: 'company_registration_certificate.jpg',
      type: VerificationDocumentType.image,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 11, 3),
      issuedIdNumber: '601234567',
      issuerAuthority: 'Office of the Company Registrar, Nepal',
    ),
    VerificationDocumentModel(
      id: 'biz-pan-doc-2',
      title: 'PAN / Tax Clearance Certificate',
      fileName: 'pan_clearance_certificate.pdf',
      type: VerificationDocumentType.pdf,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 11, 3),
      issuedIdNumber: 'PAN-601234567',
      issuerAuthority: 'Inland Revenue Department (IRD), Nepal',
    ),
    VerificationDocumentModel(
      id: 'biz-food-doc-3',
      title: 'Food Safety & Hygiene License',
      fileName: 'food_safety_license_2025.jpg',
      type: VerificationDocumentType.image,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 11, 4),
      issuedIdNumber: 'DFTQC-88219-NP',
      issuerAuthority: 'Department of Food Technology and Quality Control',
    ),
  ];

  static List<VerificationDocumentModel> defaultNgoDocuments() => [
    VerificationDocumentModel(
      id: 'ngo-swc-doc-1',
      title: 'Social Welfare Council (SWC) Affiliation',
      fileName: 'swc_affiliation_certificate.jpg',
      type: VerificationDocumentType.image,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 10, 15),
      issuedIdNumber: 'SWC-NP-49821',
      issuerAuthority: 'Social Welfare Council, Nepal',
    ),
    VerificationDocumentModel(
      id: 'ngo-reg-doc-2',
      title: 'District Administration Registration Letter',
      fileName: 'district_admin_registration.pdf',
      type: VerificationDocumentType.pdf,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 10, 15),
      issuedIdNumber: 'DAO-KTM-2081/142',
      issuerAuthority: 'District Administration Office, Kathmandu',
    ),
    VerificationDocumentModel(
      id: 'ngo-pan-doc-3',
      title: 'NGO PAN & Tax Exemption Certificate',
      fileName: 'ngo_pan_tax_exempt.jpg',
      type: VerificationDocumentType.image,
      status: VerificationDocumentStatus.verified,
      submittedOn: DateTime(2025, 10, 16),
      issuedIdNumber: 'PAN-601298451',
      issuerAuthority: 'Inland Revenue Department (IRD), Nepal',
    ),
  ];
}
