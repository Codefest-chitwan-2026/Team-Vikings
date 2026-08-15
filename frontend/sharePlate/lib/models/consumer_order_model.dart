import 'donation_model.dart';

enum ConsumerOrderStatus { readyForPickup, completed, cancelled }

class ConsumerOrderModel {
  final String id;
  final String orderCode;
  final String title;
  final String storeName;
  final String storePhone;
  final String pickupAddress;
  final double distanceKm;
  final double originalPrice;
  final double discountedPrice;
  final FoodCategory category;
  final DateTime orderTime;
  final int pickupWindowMinutes;
  final String instructions;
  final ConsumerOrderStatus status;
  final String? qrCode;
  final dynamic donationId;
  final Map<String, dynamic>? rawJson;

  ConsumerOrderModel({
    required this.id,
    required this.orderCode,
    required this.title,
    required this.storeName,
    required this.storePhone,
    required this.pickupAddress,
    this.distanceKm = 1.0,
    required this.originalPrice,
    required this.discountedPrice,
    this.category = FoodCategory.veg,
    required this.orderTime,
    this.pickupWindowMinutes = 45,
    this.instructions = 'Show your verification code at the cash counter to collect your meal.',
    this.status = ConsumerOrderStatus.readyForPickup,
    this.qrCode,
    this.donationId,
    this.rawJson,
  });

  bool get isActive => status == ConsumerOrderStatus.readyForPickup;
  double get savedAmount => originalPrice - discountedPrice;

  factory ConsumerOrderModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'READY_FOR_PICKUP').toString().toUpperCase();
    ConsumerOrderStatus orderStatus;
    if (rawStatus.contains('COMPLETE') || rawStatus.contains('PICKED_UP')) {
      orderStatus = ConsumerOrderStatus.completed;
    } else if (rawStatus.contains('CANCEL')) {
      orderStatus = ConsumerOrderStatus.cancelled;
    } else {
      orderStatus = ConsumerOrderStatus.readyForPickup;
    }

    final rawFoodType = (json['category'] ?? json['food_type'] ?? 'VEG').toString().toUpperCase();
    final FoodCategory cat = rawFoodType.contains('NON')
        ? FoodCategory.nonVeg
        : (rawFoodType.contains('MIX') ? FoodCategory.mixed : FoodCategory.veg);

    String? qr;
    if (json['pickup_ticket'] is Map<String, dynamic>) {
      qr = json['pickup_ticket']['qr_code']?.toString();
    } else if (json['qr_code'] != null) {
      qr = json['qr_code'].toString();
    }

    DateTime parsedTime = DateTime.now();
    if (json['order_time'] != null || json['created_at'] != null) {
      try {
        parsedTime = DateTime.parse((json['order_time'] ?? json['created_at']).toString());
      } catch (_) {}
    }

    return ConsumerOrderModel(
      id: (json['id'] ?? '').toString(),
      orderCode: (json['order_code'] ?? 'ORD-${json['id'] ?? 1001}').toString(),
      title: json['title'] ?? 'Surplus Meal Deal',
      storeName: json['store_name'] ?? 'Local Food Business',
      storePhone: json['store_phone'] ?? '',
      pickupAddress: json['pickup_address'] ?? 'Kathmandu',
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '1.0') ?? 1.0,
      originalPrice: double.tryParse(json['original_price']?.toString() ?? '300.0') ?? 300.0,
      discountedPrice: double.tryParse(json['discounted_price']?.toString() ?? '120.0') ?? 120.0,
      category: cat,
      orderTime: parsedTime,
      pickupWindowMinutes: int.tryParse(json['pickup_window_minutes']?.toString() ?? '45') ?? 45,
      instructions: json['instructions'] ?? 'Show your verification code at the cash counter to collect your meal.',
      status: orderStatus,
      qrCode: qr,
      donationId: json['donation'],
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'title': title,
      'store_name': storeName,
      'store_phone': storePhone,
      'pickup_address': pickupAddress,
      'distance_km': distanceKm,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'category': category.name.toUpperCase(),
      'order_time': orderTime.toIso8601String(),
      'pickup_window_minutes': pickupWindowMinutes,
      'instructions': instructions,
      'status': status.name.toUpperCase(),
      'qr_code': qrCode,
      'donation': donationId,
    };
  }
}
