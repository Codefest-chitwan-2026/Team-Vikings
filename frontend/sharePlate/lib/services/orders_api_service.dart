import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class OrdersApiService {
  final ApiClient _apiClient;

  OrdersApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/orders/
  Future<List<dynamic>> getOrders({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.orders,
      token: token,
    );
    return response is List ? response : [];
  }

  /// POST /api/orders/
  Future<Map<String, dynamic>> createOrder({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.orders,
      body: body,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/reservations/
  Future<List<dynamic>> getReservations({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.reservations,
      token: token,
    );
    return response is List ? response : [];
  }

  /// GET /api/claims/
  Future<List<dynamic>> getClaims({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.claims,
      token: token,
    );
    return response is List ? response : [];
  }
}
