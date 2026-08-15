import 'package:flutter/material.dart';
import 'donation_model.dart';

class SurplusSponsorItem {
  final String id;
  final String donorName;
  final String donorType; // 'Hotel & Buffet', 'Bakery & Cafe', 'Banquet & Catering', 'Restaurant'
  final String donorAddress;
  final String donorPhone;
  final double distanceKm;
  final String foodTitle;
  final FoodCategory category;
  final int totalMeals;
  final int remainingMeals;
  final String quantityUnit; // 'Meals', 'Boxes', 'Packs', 'Trays'
  final String servesApprox;
  final double sponsorPricePerMeal; // e.g. 80.0
  final double originalPricePerMeal; // e.g. 350.0
  final int minutesLeft;
  final String cookedAgo;
  final String destinationNgo;
  final String destinationNgoCategory; // 'Orphanage', 'Elderly Care', 'Shelter'
  final String destinationAddress;
  final String description;
  final List<String> itemsIncluded;
  final String packagingInfo;
  final String hygieneRating;
  final List<Color> bannerGradient;
  final String? imageAsset;
  final bool isActive;

  const SurplusSponsorItem({
    required this.id,
    required this.donorName,
    required this.donorType,
    required this.donorAddress,
    required this.donorPhone,
    required this.distanceKm,
    required this.foodTitle,
    required this.category,
    required this.totalMeals,
    required this.remainingMeals,
    this.quantityUnit = 'Meals',
    required this.servesApprox,
    required this.sponsorPricePerMeal,
    required this.originalPricePerMeal,
    required this.minutesLeft,
    required this.cookedAgo,
    required this.destinationNgo,
    required this.destinationNgoCategory,
    required this.destinationAddress,
    required this.description,
    required this.itemsIncluded,
    this.packagingInfo = 'Sealed thermal containers & tamper-proof meal boxes',
    this.hygieneRating = 'A+ Grade (ISO Food Safety Verified)',
    required this.bannerGradient,
    this.imageAsset,
    this.isActive = true,
  });

  double get totalSponsorPrice => remainingMeals * sponsorPricePerMeal;
  double get totalOriginalPrice => remainingMeals * originalPricePerMeal;
  double get totalSavings => totalOriginalPrice - totalSponsorPrice;
  int get discountPercent =>
      (((originalPricePerMeal - sponsorPricePerMeal) / originalPricePerMeal) * 100).round();

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';

  factory SurplusSponsorItem.fromJson(Map<String, dynamic> json) {
    final rawCat = (json['category'] ?? 'VEG').toString().toUpperCase();
    final FoodCategory cat = rawCat.contains('NON')
        ? FoodCategory.nonVeg
        : (rawCat.contains('MIX') ? FoodCategory.mixed : FoodCategory.veg);

    List<String> items = [];
    if (json['items_included'] is List) {
      items = (json['items_included'] as List).map((e) => e.toString()).toList();
    } else if (json['items_included'] is String && (json['items_included'] as String).isNotEmpty) {
      items = (json['items_included'] as String).split(',');
    } else {
      items = ['Fresh Cooked Meals', 'Thermal Sealed Packaging'];
    }

    return SurplusSponsorItem(
      id: (json['id'] ?? '').toString(),
      donorName: json['donor_name'] ?? 'Local Food Business',
      donorType: json['donor_type'] ?? 'Restaurant',
      donorAddress: json['donor_address'] ?? 'Kathmandu',
      donorPhone: json['donor_phone'] ?? '',
      distanceKm: double.tryParse(json['distance_km']?.toString() ?? '1.0') ?? 1.0,
      foodTitle: json['food_title'] ?? 'Surplus Meal Package',
      category: cat,
      totalMeals: int.tryParse(json['total_meals']?.toString() ?? '20') ?? 20,
      remainingMeals: int.tryParse(json['remaining_meals']?.toString() ?? '20') ?? 20,
      quantityUnit: json['quantity_unit'] ?? 'Meals',
      servesApprox: json['serves_approx'] ?? '${json['total_meals'] ?? 20} people',
      sponsorPricePerMeal: double.tryParse(json['sponsor_price_per_meal']?.toString() ?? '80.0') ?? 80.0,
      originalPricePerMeal: double.tryParse(json['original_price_per_meal']?.toString() ?? '350.0') ?? 350.0,
      minutesLeft: int.tryParse(json['minutes_left']?.toString() ?? '120') ?? 120,
      cookedAgo: json['cooked_ago'] ?? '45 mins ago',
      destinationNgo: json['destination_ngo'] ?? 'Sneha Children Home',
      destinationNgoCategory: json['destination_ngo_category'] ?? 'Orphanage',
      destinationAddress: json['destination_address'] ?? 'Sanepa, Lalitpur',
      description: json['description'] ?? 'Nutritious surplus meal package available for community sponsorship.',
      itemsIncluded: items,
      packagingInfo: json['packaging_info'] ?? 'Sealed thermal containers & tamper-proof meal boxes',
      hygieneRating: json['hygiene_rating'] ?? '⭐️ 4.9 Food Safety Certified',
      bannerGradient: _getGradient(cat),
      imageAsset: json['image']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  static List<Color> _getGradient(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return const [Color(0xFF1B5E20), Color(0xFF2E7D32)];
      case FoodCategory.nonVeg:
        return const [Color(0xFF8E24AA), Color(0xFF6A1B9A)];
      case FoodCategory.mixed:
        return const [Color(0xFFE65100), Color(0xFFEF6C00)];
    }
  }

  static const List<SurplusSponsorItem> mockSurplusItems = [];
}
