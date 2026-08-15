import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class ProfileApiService {
  final ApiClient _apiClient;

  ProfileApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetch the current user's profile from the backend: GET /api/profiles/me/
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
}
