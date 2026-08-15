import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class SponsorshipApiService {
  final ApiClient _apiClient;

  SponsorshipApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/sponsorship-items/
  Future<List<dynamic>> getSponsorshipItems({String? token}) async {
    final response = await _apiClient.get(
      ApiConstants.sponsorshipItems,
      token: token,
    );
    return response is List ? response : [];
  }

  /// GET /api/sponsorships/
  Future<List<dynamic>> getSponsorships({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.sponsorships,
      token: token,
    );
    return response is List ? response : [];
  }

  /// POST /api/sponsorships/
  Future<Map<String, dynamic>> createSponsorship({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.sponsorships,
      body: body,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }
}
