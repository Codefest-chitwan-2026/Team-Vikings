import '../models/contribution_model.dart';
import '../services/contributions_api_service.dart';

abstract class IContributionRepository {
  Future<List<ContributionItem>> getContributions({required String token});

  Future<ContributionItem> getContributionDetail({
    required String token,
    required dynamic id,
  });
}

class ContributionRepository implements IContributionRepository {
  final ContributionsApiService _apiService;

  ContributionRepository({ContributionsApiService? apiService})
      : _apiService = apiService ?? ContributionsApiService();

  @override
  Future<List<ContributionItem>> getContributions({required String token}) async {
    final list = await _apiService.getContributions(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ContributionItem.fromJson(e))
        .toList();
  }

  @override
  Future<ContributionItem> getContributionDetail({
    required String token,
    required dynamic id,
  }) async {
    final res = await _apiService.getContributionDetail(token: token, id: id);
    return ContributionItem.fromJson(res);
  }
}
