import '../models/donation_model.dart';
import '../services/donations_api_service.dart';

abstract class IDonationRepository {
  Future<List<DonationItem>> getDonations({
    required String token,
    String? foodType,
    String? listingType,
    String? status,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  Future<DonationItem> createDonation({
    required String token,
    required Map<String, String> fields,
    String? imagePath,
  });

  Future<DonationItem> getDonationDetail({
    required String token,
    required dynamic id,
  });

  Future<List<DonationItem>> getNgoPriorityDonations({required String token});

  Future<List<DonationItem>> getFlashSales({required String token});

  Future<Map<String, dynamic>> claimDonation({
    required String token,
    required dynamic id,
    String pickupMethod = 'SELF',
    DateTime? scheduledPickupStart,
    DateTime? scheduledPickupEnd,
    String? volunteerName,
    String? volunteerPhone,
    String? donorNote,
    int? peopleServedConfirmed,
  });

  Future<Map<String, dynamic>> reserveDonation({
    required String token,
    required dynamic id,
  });

  Future<DonationItem> convertToFlashSale({
    required String token,
    required dynamic id,
    double? flashSalePrice,
  });

  Future<DonationItem> cancelDonation({
    required String token,
    required dynamic id,
  });

  Future<Map<String, dynamic>> verifyPickup({
    required String token,
    required String qrCode,
  });

  Future<List<dynamic>> getClaims({required String token});

  Future<List<dynamic>> getReservations({required String token});
}

class DonationRepository implements IDonationRepository {
  final DonationsApiService _apiService;

  DonationRepository({DonationsApiService? apiService})
      : _apiService = apiService ?? DonationsApiService();

  @override
  Future<List<DonationItem>> getDonations({
    required String token,
    String? foodType,
    String? listingType,
    String? status,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    print("Reached!!");
    final list = await _apiService.getDonations(
      token: token,
      foodType: foodType,
      listingType: listingType,
      status: status,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
    print(list);

    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => DonationItem.fromJson(e))
        .toList();
  }

  @override
  Future<DonationItem> createDonation({
    required String token,
    required Map<String, String> fields,
    String? imagePath,
  }) async {
    final res = await _apiService.createDonation(
      token: token,
      fields: fields,
      imagePath: imagePath,
    );
    return DonationItem.fromJson(res);
  }

  @override
  Future<DonationItem> getDonationDetail({
    required String token,
    required dynamic id,
  }) async {
    final res = await _apiService.getDonationDetail(token: token, id: id);
    return DonationItem.fromJson(res);
  }

  @override
  Future<List<DonationItem>> getNgoPriorityDonations({required String token}) async {
    final list = await _apiService.getNgoPriorityDonations(token: token);
    print("Hi");
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => DonationItem.fromJson(e))
        .toList();
  }

  @override
  Future<List<DonationItem>> getFlashSales({required String token}) async {
    final list = await _apiService.getFlashSales(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => DonationItem.fromJson(e))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> claimDonation({
    required String token,
    required dynamic id,
    String pickupMethod = 'SELF',
    DateTime? scheduledPickupStart,
    DateTime? scheduledPickupEnd,
    String? volunteerName,
    String? volunteerPhone,
    String? donorNote,
    int? peopleServedConfirmed,
  }) async {
    return await _apiService.claimDonation(
      token: token,
      id: id,
      pickupMethod: pickupMethod,
      scheduledPickupStart: scheduledPickupStart,
      scheduledPickupEnd: scheduledPickupEnd,
      volunteerName: volunteerName,
      volunteerPhone: volunteerPhone,
      donorNote: donorNote,
      peopleServedConfirmed: peopleServedConfirmed,
    );
  }

  @override
  Future<Map<String, dynamic>> reserveDonation({
    required String token,
    required dynamic id,
  }) async {
    return await _apiService.reserveDonation(token: token, id: id);
  }

  @override
  Future<DonationItem> convertToFlashSale({
    required String token,
    required dynamic id,
    double? flashSalePrice,
  }) async {
    final res = await _apiService.convertToFlashSale(
      token: token,
      id: id,
      flashSalePrice: flashSalePrice,
    );
    if (res.containsKey('donation') && res['donation'] is Map<String, dynamic>) {
      return DonationItem.fromJson(res['donation']);
    }
    return DonationItem.fromJson(res);
  }

  @override
  Future<DonationItem> cancelDonation({
    required String token,
    required dynamic id,
  }) async {
    final res = await _apiService.cancelDonation(token: token, id: id);
    if (res.containsKey('donation') && res['donation'] is Map<String, dynamic>) {
      return DonationItem.fromJson(res['donation']);
    }
    return DonationItem.fromJson(res);
  }

  @override
  Future<Map<String, dynamic>> verifyPickup({
    required String token,
    required String qrCode,
  }) async {
    return await _apiService.verifyPickup(token: token, qrCode: qrCode);
  }

  @override
  Future<List<dynamic>> getClaims({required String token}) async {
    return await _apiService.getClaims(token: token);
  }

  @override
  Future<List<dynamic>> getReservations({required String token}) async {
    return await _apiService.getReservations(token: token);
  }
}
