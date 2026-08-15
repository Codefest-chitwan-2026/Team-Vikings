import '../models/claim_hold_model.dart';
import '../models/donation_model.dart';
import '../services/listing_flow_api_service.dart';

abstract class IListingFlowRepository {
  Future<DonationItem> getListingFlowDetail({
    required String token,
    required dynamic id,
  });

  Future<Map<String, dynamic>> getListingUpdate({
    required String token,
    required dynamic id,
  });

  Future<Map<String, dynamic>> adjustPrice({
    required String token,
    required dynamic id,
    required double flashSalePrice,
  });

  Future<Map<String, dynamic>> keepDonationOnly({
    required String token,
    required dynamic id,
  });

  Future<List<ClaimHoldModel>> getClaimHolds({required String token});

  Future<ClaimHoldModel> createClaimHold({
    required String token,
    required dynamic donationId,
  });

  Future<Map<String, dynamic>> confirmClaimHold({
    required String token,
    required dynamic holdId,
    required Map<String, dynamic> payload,
  });

  Future<void> cancelClaimHold({
    required String token,
    required dynamic holdId,
  });

  Future<PickupQRPayload> getPickupQrByClaim({
    required String token,
    required dynamic claimId,
  });

  Future<PickupQRPayload> getPickupQrByTicket({
    required String token,
    required dynamic ticketId,
  });

  Future<Map<String, dynamic>> verifyPickup({
    required String token,
    String? qrCode,
    String? manualCode,
  });

  Future<Map<String, dynamic>> previewExpectedPickup({
    required String token,
    required String code,
  });
}

class ListingFlowRepository implements IListingFlowRepository {
  final ListingFlowApiService _apiService;

  ListingFlowRepository({ListingFlowApiService? apiService})
      : _apiService = apiService ?? ListingFlowApiService();

  @override
  Future<DonationItem> getListingFlowDetail({
    required String token,
    required dynamic id,
  }) async {
    final res = await _apiService.getListingFlowDetail(token: token, id: id);
    return DonationItem.fromJson(res);
  }

  @override
  Future<Map<String, dynamic>> getListingUpdate({
    required String token,
    required dynamic id,
  }) async {
    return await _apiService.getListingUpdate(token: token, id: id);
  }

  @override
  Future<Map<String, dynamic>> adjustPrice({
    required String token,
    required dynamic id,
    required double flashSalePrice,
  }) async {
    return await _apiService.adjustPrice(
      token: token,
      id: id,
      flashSalePrice: flashSalePrice,
    );
  }

  @override
  Future<Map<String, dynamic>> keepDonationOnly({
    required String token,
    required dynamic id,
  }) async {
    return await _apiService.keepDonationOnly(token: token, id: id);
  }

  @override
  Future<List<ClaimHoldModel>> getClaimHolds({required String token}) async {
    final list = await _apiService.getClaimHolds(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ClaimHoldModel.fromJson(e))
        .toList();
  }

  @override
  Future<ClaimHoldModel> createClaimHold({
    required String token,
    required dynamic donationId,
  }) async {
    final res = await _apiService.createClaimHold(token: token, donationId: donationId);
    if (res.containsKey('hold') && res['hold'] is Map<String, dynamic>) {
      return ClaimHoldModel.fromJson(res['hold']);
    }
    return ClaimHoldModel.fromJson(res);
  }

  @override
  Future<Map<String, dynamic>> confirmClaimHold({
    required String token,
    required dynamic holdId,
    required Map<String, dynamic> payload,
  }) async {
    return await _apiService.confirmClaimHold(
      token: token,
      holdId: holdId,
      payload: payload,
    );
  }

  @override
  Future<void> cancelClaimHold({
    required String token,
    required dynamic holdId,
  }) async {
    await _apiService.cancelClaimHold(token: token, holdId: holdId);
  }

  @override
  Future<PickupQRPayload> getPickupQrByClaim({
    required String token,
    required dynamic claimId,
  }) async {
    final res = await _apiService.getPickupQrByClaim(token: token, claimId: claimId);
    return PickupQRPayload.fromJson(res);
  }

  @override
  Future<PickupQRPayload> getPickupQrByTicket({
    required String token,
    required dynamic ticketId,
  }) async {
    final res = await _apiService.getPickupQrByTicket(token: token, ticketId: ticketId);
    return PickupQRPayload.fromJson(res);
  }

  @override
  Future<Map<String, dynamic>> verifyPickup({
    required String token,
    String? qrCode,
    String? manualCode,
  }) async {
    return await _apiService.verifyPickup(
      token: token,
      qrCode: qrCode,
      manualCode: manualCode,
    );
  }

  @override
  Future<Map<String, dynamic>> previewExpectedPickup({
    required String token,
    required String code,
  }) async {
    return await _apiService.previewExpectedPickup(token: token, code: code);
  }
}
