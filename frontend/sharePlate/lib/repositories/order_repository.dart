import '../models/consumer_order_model.dart';
import '../services/orders_api_service.dart';

abstract class IOrderRepository {
  Future<List<ConsumerOrderModel>> getOrders({required String token});

  Future<ConsumerOrderModel> createOrder({
    required String token,
    required Map<String, dynamic> body,
  });

  Future<List<dynamic>> getReservations({required String token});

  Future<List<dynamic>> getClaims({required String token});
}

class OrderRepository implements IOrderRepository {
  final OrdersApiService _apiService;

  OrderRepository({OrdersApiService? apiService})
      : _apiService = apiService ?? OrdersApiService();

  @override
  Future<List<ConsumerOrderModel>> getOrders({required String token}) async {
    final list = await _apiService.getOrders(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => ConsumerOrderModel.fromJson(e))
        .toList();
  }

  @override
  Future<ConsumerOrderModel> createOrder({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final res = await _apiService.createOrder(token: token, body: body);
    return ConsumerOrderModel.fromJson(res);
  }

  @override
  Future<List<dynamic>> getReservations({required String token}) async {
    return await _apiService.getReservations(token: token);
  }

  @override
  Future<List<dynamic>> getClaims({required String token}) async {
    return await _apiService.getClaims(token: token);
  }
}
