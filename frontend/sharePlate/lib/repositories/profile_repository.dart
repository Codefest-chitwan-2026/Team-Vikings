import '../core/constants/api_constants.dart';
import '../models/nearby_ngo_model.dart';
import '../models/verification_document_model.dart';
import '../services/profile_api_service.dart';

abstract class IProfileRepository {
  Future<Map<String, dynamic>> getMyProfile({required String token});

  Future<Map<String, dynamic>> updateMyProfile({
    required String token,
    required Map<String, String> fields,
    String? registrationDocumentPath,
  });

  Future<List<VerificationDocumentModel>> getVerificationDocuments({required String token});

  Future<VerificationDocumentModel> uploadVerificationDocument({
    required String token,
    required Map<String, String> fields,
    required String filePath,
  });

  Future<List<NearbyNgo>> getNearbyNgos({
    double? latitude,
    double? longitude,
    double? radiusKm,
  });
}

class ProfileRepository implements IProfileRepository {
  final ProfileApiService _apiService;

  ProfileRepository({ProfileApiService? apiService})
      : _apiService = apiService ?? ProfileApiService();

  @override
  Future<Map<String, dynamic>> getMyProfile({required String token}) async {
    return await _apiService.getMyProfile(token: token);
  }

  @override
  Future<Map<String, dynamic>> updateMyProfile({
    required String token,
    required Map<String, String> fields,
    String? registrationDocumentPath,
  }) async {
    return await _apiService.updateMyProfile(
      token: token,
      fields: fields,
      registrationDocumentPath: registrationDocumentPath,
    );
  }

  @override
  Future<List<VerificationDocumentModel>> getVerificationDocuments({required String token}) async {
    final list = await _apiService.getVerificationDocuments(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) {
          final docFile = e['document_file']?.toString();
          String? photoUrl;
          if (docFile != null && docFile.isNotEmpty) {
            photoUrl = docFile.startsWith('http')
                ? docFile
                : (docFile.startsWith('/') ? '${ApiConstants.baseUrl}$docFile' : '${ApiConstants.baseUrl}/$docFile');
          }
          final fName = (e['file_name'] != null && e['file_name'].toString().isNotEmpty)
              ? e['file_name'].toString()
              : (docFile != null ? docFile.split('/').last : 'document.pdf');
          final isPdf = (e['document_type'] ?? '').toString().toUpperCase() == 'PDF' || fName.toLowerCase().endsWith('.pdf');

          return VerificationDocumentModel(
            id: (e['id'] ?? '').toString(),
            title: e['title'] ?? 'Verification Document',
            fileName: fName,
            type: isPdf ? VerificationDocumentType.pdf : VerificationDocumentType.image,
            status: _parseDocStatus(e['status']),
            submittedOn: e['submitted_on'] != null
                ? DateTime.tryParse(e['submitted_on'].toString()) ?? DateTime.now()
                : DateTime.now(),
            issuedIdNumber: e['issued_id_number']?.toString() ?? '',
            reviewNote: e['review_note']?.toString(),
            issuerAuthority: e['issuer_authority']?.toString() ?? '',
            photoUrl: photoUrl,
          );
        })
        .toList();
  }

  @override
  Future<VerificationDocumentModel> uploadVerificationDocument({
    required String token,
    required Map<String, String> fields,
    required String filePath,
  }) async {
    final res = await _apiService.uploadVerificationDocument(
      token: token,
      fields: fields,
      filePath: filePath,
    );
    final docFile = res['document_file']?.toString();
    String? photoUrl;
    if (docFile != null && docFile.isNotEmpty) {
      photoUrl = docFile.startsWith('http')
          ? docFile
          : (docFile.startsWith('/') ? '${ApiConstants.baseUrl}$docFile' : '${ApiConstants.baseUrl}/$docFile');
    }
    final fName = (res['file_name'] != null && res['file_name'].toString().isNotEmpty)
        ? res['file_name'].toString()
        : filePath.split(RegExp(r'[\\/]')).last;
    final isPdf = (res['document_type'] ?? '').toString().toUpperCase() == 'PDF' || fName.toLowerCase().endsWith('.pdf');

    return VerificationDocumentModel(
      id: (res['id'] ?? 'doc-${DateTime.now().millisecondsSinceEpoch}').toString(),
      title: res['title'] ?? fields['title'] ?? 'Uploaded Document',
      fileName: fName,
      type: isPdf ? VerificationDocumentType.pdf : VerificationDocumentType.image,
      status: _parseDocStatus(res['status']),
      submittedOn: res['submitted_on'] != null
          ? DateTime.tryParse(res['submitted_on'].toString()) ?? DateTime.now()
          : DateTime.now(),
      issuedIdNumber: res['issued_id_number']?.toString() ?? fields['issued_id_number'] ?? '',
      reviewNote: res['review_note']?.toString(),
      localFilePath: filePath,
      photoUrl: photoUrl,
      issuerAuthority: res['issuer_authority']?.toString() ?? fields['issuer_authority'] ?? 'Self Submitted',
    );
  }

  @override
  Future<List<NearbyNgo>> getNearbyNgos({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final list = await _apiService.getNearbyNgos(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => NearbyNgo.fromJson(e))
        .toList();
  }

  static VerificationDocumentStatus _parseDocStatus(dynamic status) {
    final s = (status ?? 'PENDING').toString().toUpperCase();
    if (s == 'APPROVED' || s == 'VERIFIED') return VerificationDocumentStatus.verified;
    if (s == 'REJECTED') return VerificationDocumentStatus.rejected;
    return VerificationDocumentStatus.pending;
  }
}
