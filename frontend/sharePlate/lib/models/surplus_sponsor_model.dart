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
  });

  double get totalSponsorPrice => remainingMeals * sponsorPricePerMeal;
  double get totalOriginalPrice => remainingMeals * originalPricePerMeal;
  double get totalSavings => totalOriginalPrice - totalSponsorPrice;
  int get discountPercent =>
      (((originalPricePerMeal - sponsorPricePerMeal) / originalPricePerMeal) * 100).round();

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';

  static const List<SurplusSponsorItem> mockSurplusItems = [
    SurplusSponsorItem(
      id: 'sp-101',
      donorName: 'Hotel Annapurna Kitchen',
      donorType: '5-Star Hotel & Buffet',
      donorAddress: 'Lazimpat, Kathmandu',
      donorPhone: '+977 9841234567',
      distanceKm: 0.8,
      foodTitle: 'Surplus Dinner Buffet: Dal Bhat, Shahi Paneer & Mixed Veg',
      category: FoodCategory.veg,
      totalMeals: 20,
      remainingMeals: 20,
      quantityUnit: 'Meals',
      servesApprox: '20-25 People',
      sponsorPricePerMeal: 80,
      originalPricePerMeal: 380,
      minutesLeft: 120,
      cookedAgo: '45 mins ago',
      destinationNgo: 'Sneha Children Home',
      destinationNgoCategory: 'Orphanage (65 Children)',
      destinationAddress: 'Sanepa, Lalitpur (1.4 km from hotel)',
      description:
          'Freshly cooked surplus from the grand evening dinner buffet. Includes aromatic Basmati rice, Yellow Tadka Dal, Shahi Paneer, Saag, and fresh salad packed in insulated thermal trays.',
      itemsIncluded: [
        'Steamed Basmati Rice (Large Trays)',
        'Yellow Dal Tadka with Ghee',
        'Rich Shahi Paneer Curry',
        'Seasonal Organic Green Saag',
        'Cucumber Salad & Tomato Achar',
      ],
      packagingInfo: 'Packed in high-grade insulated thermal delivery boxes',
      hygieneRating: '⭐️ 4.9 Food Safety & Hygiene Certified',
      bannerGradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    ),
    SurplusSponsorItem(
      id: 'sp-102',
      donorName: 'Chitwan Black Forest Bakery',
      donorType: 'Artisan Bakery & Cafe',
      donorAddress: 'Lions Chowk, Narayangarh, Chitwan',
      donorPhone: '+977 9855012345',
      distanceKm: 1.2,
      foodTitle: 'Fresh Wholewheat Croissants, Milk Buns & Veg Sandwiches',
      category: FoodCategory.mixed,
      totalMeals: 30,
      remainingMeals: 24,
      quantityUnit: 'Boxes',
      servesApprox: '24-30 Kids / Seniors',
      sponsorPricePerMeal: 60,
      originalPricePerMeal: 220,
      minutesLeft: 180,
      cookedAgo: '1 hour ago',
      destinationNgo: 'Aasha Foundation Child Center',
      destinationNgoCategory: 'Child Shelter (45 Kids)',
      destinationAddress: 'Bharatpur-10, Chitwan (0.8 km)',
      description:
          'End-of-day surplus of freshly baked wholewheat croissants, butter milk buns, and grilled vegetable cheese sandwiches made with premium ingredients.',
      itemsIncluded: [
        '12x Butter Croissants',
        '12x Soft Wholewheat Milk Buns',
        '6x Grilled Veggie & Cheese Club Sandwiches',
        'Sweet Fruit Jam & Butter Packs',
      ],
      packagingInfo: 'Individually wrapped and boxed with expiration timestamp',
      hygieneRating: '⭐️ 4.8 Artisan Bakery Hygiene Rated',
      bannerGradient: [Color(0xFFE65100), Color(0xFFEF6C00)],
    ),
    SurplusSponsorItem(
      id: 'sp-103',
      donorName: 'Himalayan Grill & Banquet',
      donorType: 'Banquet & Catering',
      donorAddress: 'Bharatpur Height, Chitwan',
      donorPhone: '+977 9841987654',
      distanceKm: 2.1,
      foodTitle: 'Deluxe Chicken Biryani Trays with Boiled Eggs & Raita',
      category: FoodCategory.nonVeg,
      totalMeals: 25,
      remainingMeals: 25,
      quantityUnit: 'Packs',
      servesApprox: '25-30 People',
      sponsorPricePerMeal: 95,
      originalPricePerMeal: 450,
      minutesLeft: 90,
      cookedAgo: '30 mins ago',
      destinationNgo: 'Manav Sewa Ashram Chitwan',
      destinationNgoCategory: 'Destitute Shelter (80 Residents)',
      destinationAddress: 'Chitwan Ashram Wing (1.5 km)',
      description:
          'Catering surplus from a corporate lunch banquet. Dum-cooked aromatic Chicken Biryani with tender chicken pieces, boiled eggs, cool mint raita, and spicy gravy.',
      itemsIncluded: [
        'Hyderabadi Dum Chicken Biryani',
        'Boiled Farm Eggs',
        'Mint & Cucumber Yogurt Raita',
        'Rich Biryani Salan Gravy',
        'Onion Lemon Salad',
      ],
      packagingInfo: 'Hot-sealed aluminum containers preserving temperature',
      hygieneRating: '⭐️ 4.9 Banquet Standard Certified',
      bannerGradient: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
    ),
    SurplusSponsorItem(
      id: 'sp-104',
      donorName: 'Everest Heritage Kitchen',
      donorType: 'Traditional Restaurant',
      donorAddress: 'Thamel, Kathmandu',
      donorPhone: '+977 9812345678',
      distanceKm: 1.5,
      foodTitle: 'Nutritious Moong Khichdi, Veg Curry & Papad Feast',
      category: FoodCategory.veg,
      totalMeals: 18,
      remainingMeals: 18,
      quantityUnit: 'Meals',
      servesApprox: '18-20 Senior Citizens',
      sponsorPricePerMeal: 70,
      originalPricePerMeal: 290,
      minutesLeft: 150,
      cookedAgo: '50 mins ago',
      destinationNgo: 'Matribhumi Elderly Sanctuary',
      destinationNgoCategory: 'Elderly Home (48 Seniors)',
      destinationAddress: 'Pashupati Area, Kathmandu (2.1 km)',
      description:
          'Gentle, highly digestible and nutritious Moong Dal Khichdi prepared with pure cow ghee, accompanied by steamed vegetables, light potato curry, and roasted papad.',
      itemsIncluded: [
        'Ghee-roasted Moong Dal & Rice Khichdi',
        'Mild Alu Cauli Tarkari',
        'Digestive Jeera Buttermilk',
        'Crispy Roasted Papad',
      ],
      packagingInfo: 'Eco-friendly sugarcane bagasse biodegradable meal containers',
      hygieneRating: '⭐️ 5.0 Senior-Grade Food Safety',
      bannerGradient: [Color(0xFF00897B), Color(0xFF00695C)],
    ),
    SurplusSponsorItem(
      id: 'sp-105',
      donorName: 'Royal Narayangarh Sweets',
      donorType: 'Sweet & Snack House',
      donorAddress: 'Main Road, Narayangarh, Chitwan',
      donorPhone: '+977 9801234567',
      distanceKm: 1.8,
      foodTitle: 'Puri Tarkari, Samosa & Gulab Jamun Breakfast / Snack Kits',
      category: FoodCategory.veg,
      totalMeals: 35,
      remainingMeals: 35,
      quantityUnit: 'Kits',
      servesApprox: '35 Children / Adults',
      sponsorPricePerMeal: 50,
      originalPricePerMeal: 180,
      minutesLeft: 210,
      cookedAgo: '40 mins ago',
      destinationNgo: 'Community Open Kitchen Chitwan',
      destinationNgoCategory: 'Community Kitchen (100 Daily)',
      destinationAddress: 'Narayani Riverbank Shelter (1.0 km)',
      description:
          'Morning fresh batches of soft fluffy puris, spicy chickpea aloo tarkari, crisp vegetable samosas, and warm sweet gulab jamuns.',
      itemsIncluded: [
        'Fresh Wheat Puris (4 pcs per kit)',
        'Spicy Chana & Aloo Tarkari',
        '1x Crunchy Vegetable Samosa',
        '1x Soft Gulab Jamun',
      ],
      packagingInfo: 'Individually sealed paper snack boxes with spoons',
      hygieneRating: '⭐️ 4.7 Pure Veg Kitchen Certified',
      bannerGradient: [Color(0xFFD84315), Color(0xFFBF360C)],
    ),
  ];
}
