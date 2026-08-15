import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class ProfileApiService {
  final ApiClient _apiClient;

  ProfileApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch the current user's profile: GET /api/profiles/me/
  Future<Map<String, dynamic>> getMyProfile({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.profileMe,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// Update the current user's profile: PATCH /api/profiles/me/
  Future<Map<String, dynamic>> updateMyProfile({
    required String token,
    required Map<String, String> fields,
    String? registrationDocumentPath,
  }) async {
    if (registrationDocumentPath != null && registrationDocumentPath.isNotEmpty) {
      final response = await _apiClient.patchMultipart(
        ApiConstants.profileMe,
        fields: fields,
        filePaths: {'registration_document': registrationDocumentPath},
        token: token,
      );
      return response is Map<String, dynamic> ? response : {};
    } else {
      final response = await _apiClient.patch(
        ApiConstants.profileMe,
        body: fields,
        token: token,
      );
      return response is Map<String, dynamic> ? response : {};
    }
  }

  /// Get verification documents: GET /api/profiles/documents/
  Future<List<dynamic>> getVerificationDocuments({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.profileDocuments,
      token: token,
    );
    return response is List ? response : [];
  }

  /// Upload a verification document: POST /api/profiles/documents/
  Future<Map<String, dynamic>> uploadVerificationDocument({
    required String token,
    required Map<String, String> fields,
    required String filePath,
  }) async {
    final response = await _apiClient.postMultipart(
      ApiConstants.profileDocuments,
      fields: fields,
      filePaths: {'document_file': filePath},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// Get nearby verified NGOs: GET /api/profiles/nearby-ngos/
  Future<List<dynamic>> getNearbyNgos({
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final queryParams = <String, String>{};
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (radiusKm != null) queryParams['radius_km'] = radiusKm.toString();

    var url = ApiConstants.nearbyNgos;
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      url = '$url?$queryString';
    }

    final response = await _apiClient.get(url);
    return response is List ? response : [];
  }
}
