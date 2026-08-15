import '../models/surplus_sponsor_model.dart';
import '../services/sponsorship_api_service.dart';

abstract class ISponsorshipRepository {
  Future<List<SurplusSponsorItem>> getSponsorshipItems({String? token});

  Future<List<dynamic>> getSponsorships({required String token});

  Future<Map<String, dynamic>> createSponsorship({
    required String token,
    required Map<String, dynamic> body,
  });
}

class SponsorshipRepository implements ISponsorshipRepository {
  final SponsorshipApiService _apiService;

  SponsorshipRepository({SponsorshipApiService? apiService})
      : _apiService = apiService ?? SponsorshipApiService();

  @override
  Future<List<SurplusSponsorItem>> getSponsorshipItems({String? token}) async {
    final list = await _apiService.getSponsorshipItems(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => SurplusSponsorItem.fromJson(e))
        .toList();
  }

  @override
  Future<List<dynamic>> getSponsorships({required String token}) async {
    return await _apiService.getSponsorships(token: token);
  }

  @override
  Future<Map<String, dynamic>> createSponsorship({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    return await _apiService.createSponsorship(token: token, body: body);
  }
}
