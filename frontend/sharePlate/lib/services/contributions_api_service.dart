import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class ContributionsApiService {
  final ApiClient _apiClient;

  ContributionsApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/contributions/
  Future<List<dynamic>> getContributions({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.contributions,
      token: token,
    );
    return response is List ? response : [];
  }

  /// GET /api/contributions/{id}/
  Future<Map<String, dynamic>> getContributionDetail({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.contributionDetail(id),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }
}
