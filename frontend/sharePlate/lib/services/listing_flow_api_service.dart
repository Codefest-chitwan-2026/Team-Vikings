import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class ListingFlowApiService {
  final ApiClient _apiClient;

  ListingFlowApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/listing-flow/{id}/detail/
  Future<Map<String, dynamic>> getListingFlowDetail({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.listingFlowDetail(id),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/listing-flow/{id}/listing-update/
  Future<Map<String, dynamic>> getListingUpdate({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.listingFlowUpdate(id),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/listing-flow/{id}/adjust-price/
  Future<Map<String, dynamic>> adjustPrice({
    required String token,
    required dynamic id,
    required double flashSalePrice,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.listingFlowAdjustPrice(id),
      body: {'flash_sale_price': flashSalePrice},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/listing-flow/{id}/keep-donation-only/
  Future<Map<String, dynamic>> keepDonationOnly({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.listingFlowKeepDonationOnly(id),
      body: {},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/claim-holds/
  Future<List<dynamic>> getClaimHolds({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.claimHolds,
      token: token,
    );
    return response is List ? response : [];
  }

  /// POST /api/claim-holds/
  Future<Map<String, dynamic>> createClaimHold({
    required String token,
    required dynamic donationId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.claimHolds,
      body: {'donation_id': donationId},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/claim-holds/{id}/confirm/
  Future<Map<String, dynamic>> confirmClaimHold({
    required String token,
    required dynamic holdId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.claimHoldConfirm(holdId),
      body: payload,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/claim-holds/{id}/cancel/
  Future<Map<String, dynamic>> cancelClaimHold({
    required String token,
    required dynamic holdId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.claimHoldCancel(holdId),
      body: {},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/pickup-qr/by-claim/{claim_id}/
  Future<Map<String, dynamic>> getPickupQrByClaim({
    required String token,
    required dynamic claimId,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.pickupQrByClaim(claimId),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/pickup-qr/by-ticket/{ticket_id}/
  Future<Map<String, dynamic>> getPickupQrByTicket({
    required String token,
    required dynamic ticketId,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.pickupQrByTicket(ticketId),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/verify-pickup/
  Future<Map<String, dynamic>> verifyPickup({
    required String token,
    String? qrCode,
    String? manualCode,
  }) async {
    final body = <String, dynamic>{};
    if (qrCode != null && qrCode.isNotEmpty) body['qr_code'] = qrCode;
    if (manualCode != null && manualCode.isNotEmpty) body['manual_code'] = manualCode;

    final response = await _apiClient.post(
      ApiConstants.verifyPickupEndpoint,
      body: body,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/verify-pickup/expected/{code}/
  Future<Map<String, dynamic>> previewExpectedPickup({
    required String token,
    required String code,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.verifyPickupExpected(code),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }
}
