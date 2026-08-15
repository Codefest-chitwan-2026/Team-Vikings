import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class DonationsApiService {
  final ApiClient _apiClient;

  DonationsApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/donations/ with optional filters
  Future<List<dynamic>> getDonations({
    required String token,
    String? foodType,
    String? listingType,
    String? status,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final queryParams = <String, String>{};
    if (foodType != null && foodType.isNotEmpty) queryParams['food_type'] = foodType;
    if (listingType != null && listingType.isNotEmpty) queryParams['listing_type'] = listingType;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (latitude != null) queryParams['latitude'] = latitude.toString();
    if (longitude != null) queryParams['longitude'] = longitude.toString();
    if (radiusKm != null) queryParams['radius_km'] = radiusKm.toString();

    var url = ApiConstants.donations;
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      url = '$url?$queryString';
    }

    final response = await _apiClient.get(url, token: token);
    return response is List ? response : [];
  }

  /// POST /api/donations/ (Create donation or flash sale)
  Future<Map<String, dynamic>> createDonation({
    required String token,
    required Map<String, String> fields,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      print("Create Donation api was entered!!");
      final response = await _apiClient.postMultipart(
        ApiConstants.donations,
        fields: fields,
        filePaths: {'image': imagePath},
        token: token,
      );
      return response is Map<String, dynamic> ? response : {};
    } else {
      final response = await _apiClient.post(
        ApiConstants.donations,
        body: fields,
        token: token,
      );
      return response is Map<String, dynamic> ? response : {};
    }
  }

  /// GET /api/donations/{id}/
  Future<Map<String, dynamic>> getDonationDetail({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.get(
      ApiConstants.donationDetail(id),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/donations/ngo_priority/
  Future<List<dynamic>> getNgoPriorityDonations({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.ngoPriority,
      token: token,
    );
    return response is List ? response : [];
  }

  /// GET /api/donations/flash_sales/
  Future<List<dynamic>> getFlashSales({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.flashSales,
      token: token,
    );
    return response is List ? response : [];
  }

  /// POST /api/donations/{id}/claim/
  Future<Map<String, dynamic>> claimDonation({
    required String token,
    required dynamic id,
    String pickupMethod = 'SELF',
  }) async {
    final response = await _apiClient.post(
      ApiConstants.claimDonation(id),
      body: {'pickup_method': pickupMethod},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/donations/{id}/reserve/
  Future<Map<String, dynamic>> reserveDonation({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.reserveDonation(id),
      body: {},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/donations/{id}/convert_to_flash_sale/
  Future<Map<String, dynamic>> convertToFlashSale({
    required String token,
    required dynamic id,
    double? flashSalePrice,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.convertToFlashSale(id),
      body: flashSalePrice != null ? {'flash_sale_price': flashSalePrice} : {},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/donations/{id}/cancel/
  Future<Map<String, dynamic>> cancelDonation({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.cancelDonation(id),
      body: {},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/donations/verify_pickup/
  Future<Map<String, dynamic>> verifyPickup({
    required String token,
    required String qrCode,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.verifyPickup,
      body: {'qr_code': qrCode},
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/claims/
  Future<List<dynamic>> getClaims({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.claims,
      token: token,
    );
    return response is List ? response : [];
  }

  /// GET /api/reservations/
  Future<List<dynamic>> getReservations({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.reservations,
      token: token,
    );
    return response is List ? response : [];
  }
}
