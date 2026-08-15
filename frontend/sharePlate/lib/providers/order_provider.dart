import 'package:flutter/material.dart';
import '../core/errors/error_sanitizer.dart';
import '../models/consumer_order_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final IOrderRepository _orderRepository;

  OrderProvider({IOrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? OrderRepository();

  List<ConsumerOrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ConsumerOrderModel> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchOrders({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _orderRepository.getOrders(token: token);
      _orders = list;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load orders at this moment.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addOrder(ConsumerOrderModel order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void markOrderCompleted(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId || o.orderCode == orderId);
    if (idx != -1) {
      final old = _orders[idx];
      _orders[idx] = ConsumerOrderModel(
        id: old.id,
        orderCode: old.orderCode,
        title: old.title,
        storeName: old.storeName,
        storePhone: old.storePhone,
        pickupAddress: old.pickupAddress,
        distanceKm: old.distanceKm,
        originalPrice: old.originalPrice,
        discountedPrice: old.discountedPrice,
        category: old.category,
        orderTime: old.orderTime,
        pickupWindowMinutes: old.pickupWindowMinutes,
        instructions: old.instructions,
        status: ConsumerOrderStatus.completed,
        qrCode: old.qrCode,
        donationId: old.donationId,
      );
      notifyListeners();
    }
  }
}
