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
        .map((e) => VerificationDocumentModel(
              id: (e['id'] ?? '').toString(),
              title: e['title'] ?? 'Verification Document',
              fileName: e['file_name'] ?? 'document.pdf',
              type: (e['document_type'] ?? 'PDF').toString().toUpperCase() == 'PDF'
                  ? VerificationDocumentType.pdf
                  : VerificationDocumentType.image,
              status: _parseDocStatus(e['status']),
              submittedOn: e['submitted_on'] != null
                  ? DateTime.tryParse(e['submitted_on'].toString()) ?? DateTime.now()
                  : DateTime.now(),
              issuedIdNumber: e['issued_id_number'] ?? '',
              issuerAuthority: e['issuer_authority'] ?? '',
            ))
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
    return VerificationDocumentModel(
      id: (res['id'] ?? 'doc-${DateTime.now().millisecondsSinceEpoch}').toString(),
      title: res['title'] ?? fields['title'] ?? 'Uploaded Document',
      fileName: filePath.split(RegExp(r'[\\/]')).last,
      type: filePath.toLowerCase().endsWith('.pdf')
          ? VerificationDocumentType.pdf
          : VerificationDocumentType.image,
      status: VerificationDocumentStatus.pending,
      submittedOn: DateTime.now(),
      issuedIdNumber: fields['issued_id_number'] ?? '',
      localFilePath: filePath,
      issuerAuthority: fields['issuer_authority'] ?? 'Self Submitted',
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
