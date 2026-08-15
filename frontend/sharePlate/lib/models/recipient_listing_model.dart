import 'package:flutter/material.dart';

import 'donation_model.dart';

enum RecipientListingFilter { doneCompleted, remaining, pending }

class RecipientListing {
  const RecipientListing({
    required this.id,
    required this.title,
    required this.headerLabel,
    required this.donorName,
    required this.area,
    required this.distanceKm,
    required this.minutesLeft,
    required this.listingType,
    required this.foodCategory,
    required this.quantity,
    required this.quantityUnit,
    required this.description,
    required this.pickupAddress,
    required this.pickupInstructions,
    required this.headerGradient,
    this.discountedPrice,
    this.originalPrice,
    this.discountPercent,
    this.status = ListingStatus.available,
    this.isNew = false,
  });

  final String id;
  final String title;
  final String headerLabel;
  final String donorName;
  final String area;
  final double distanceKm;
  final int minutesLeft;
  final ListingType listingType;
  final FoodCategory foodCategory;
  final int quantity;
  final String quantityUnit;
  final String description;
  final String pickupAddress;
  final String pickupInstructions;
  final List<Color> headerGradient;
  final double? discountedPrice;
  final double? originalPrice;
  final int? discountPercent;
  final ListingStatus status;
  final bool isNew;

  bool get isFree => listingType == ListingType.donateFree;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  String get subtitle => '$donorName · $area · $distanceLabel';

  String get browseSubtitle => '$donorName · $distanceLabel';

  String get foodTypeLabel {
    switch (foodCategory) {
      case FoodCategory.veg:
        return 'Veg';
      case FoodCategory.nonVeg:
        return 'Non-veg';
      case FoodCategory.mixed:
        return 'Mixed';
    }
  }

  String get claimBadgeLabel =>
      isFree ? 'FREE - CLAIM' : '${discountPercent ?? 0}% OFF';

  String get cardBadgeLabel => isFree ? 'FREE' : '${discountPercent ?? 0}% OFF';

  String? get priceLabel =>
      discountedPrice == null ? null : 'Rs ${discountedPrice!.toInt()}';
}

class RecipientListingModel {
  static const organizationName = 'Aasha Foundation';

  static const stats = (
  mealsClaimed: 13,
  activeListings: 4,
  savedOnDeals: 'Rs 2.1k',
  );

  static const listings = [
    RecipientListing(
      id: '1',
      title: 'Dal Bhat trays',
      headerLabel: '18 Dal Bhat trays · Hotel Annapurna',
      donorName: 'Hotel Annapurna Kitchen',
      area: 'Lazimpat',
      distanceKm: 1.2,
      minutesLeft: 40,
      listingType: ListingType.donateFree,
      foodCategory: FoodCategory.veg,
      quantity: 18,
      quantityUnit: 'Trays',
      description:
      'Freshly cooked rice, dal and mixed vegetable curry from tonight\'s buffet service. Packed in sealed trays, ready for immediate pickup.',
      pickupAddress: 'Lazimpat, Kathmandu',
      pickupInstructions: 'Kitchen entrance, ask for Suman',
      headerGradient: [Color(0xFF1EAA55), Color(0xFF0F6B35)],
      status: ListingStatus.available,
    ),
    RecipientListing(
      id: '2',
      title: 'Mixed pastry box (6pc)',
      headerLabel: 'Mixed pastry box · Cafe Norling',
      donorName: 'Cafe Norling',
      area: 'Thamel',
      distanceKm: 0.9,
      minutesLeft: 25,
      listingType: ListingType.discountedSale,
      foodCategory: FoodCategory.mixed,
      quantity: 6,
      quantityUnit: 'Boxes',
      description:
      'Assorted pastries from today\'s batch — croissants, danishes and muffins. Best before tonight, sealed in bakery packaging.',
      pickupAddress: 'Thamel, Kathmandu',
      pickupInstructions: 'Counter pickup, ask for Priya',
      headerGradient: [Color(0xFFE65100), Color(0xFFB71C1C)],
      originalPrice: 400,
      discountedPrice: 120,
      discountPercent: 70,
      status: ListingStatus.available,
    ),
    RecipientListing(
      id: '3',
      title: 'Wedding catering trays',
      headerLabel: '14 Wedding catering trays · Party Palace',
      donorName: 'Party Palace Events',
      area: 'Baluwatar',
      distanceKm: 2.4,
      minutesLeft: 55,
      listingType: ListingType.donateFree,
      foodCategory: FoodCategory.mixed,
      quantity: 14,
      quantityUnit: 'Trays',
      description:
      'Leftover catering trays from a wedding reception — rice, curry, salad and dessert portions.',
      pickupAddress: 'Baluwatar, Kathmandu',
      pickupInstructions: 'Loading bay at rear entrance',
      headerGradient: [Color(0xFFF9A825), Color(0xFFE65100)],
      status: ListingStatus.claimed,
    ),
    RecipientListing(
      id: '4',
      title: 'Vegetable biryani pots',
      headerLabel: '8 Vegetable biryani pots · Spice Garden',
      donorName: 'Spice Garden Restaurant',
      area: 'Jhamsikhel',
      distanceKm: 1.8,
      minutesLeft: 20,
      listingType: ListingType.discountedSale,
      foodCategory: FoodCategory.veg,
      quantity: 8,
      quantityUnit: 'Pots',
      description:
      'Large pots of vegetable biryani prepared for a cancelled event. Still warm, suitable for immediate distribution.',
      pickupAddress: 'Jhamsikhel, Lalitpur',
      pickupInstructions: 'Main kitchen door, ring bell twice',
      headerGradient: [Color(0xFF43A047), Color(0xFF1B5E20)],
      originalPrice: 1600,
      discountedPrice: 480,
      discountPercent: 70,
      status: ListingStatus.completed,
    ),
    RecipientListing(
      id: '5',
      title: 'Momo & noodle combo trays',
      headerLabel: '12 Momo & noodle trays · Everest Kitchen',
      donorName: 'Everest Kitchen',
      area: 'Baneshwor',
      distanceKm: 1.5,
      minutesLeft: 30,
      listingType: ListingType.donateFree,
      foodCategory: FoodCategory.nonVeg,
      quantity: 12,
      quantityUnit: 'Trays',
      description:
      'Steamed chicken momos and stir-fried noodles from today\'s lunch service, packed and ready for pickup.',
      pickupAddress: 'Baneshwor, Kathmandu',
      pickupInstructions: 'Side entrance near parking, ask for Bikash',
      headerGradient: [Color(0xFF2E7D32), Color(0xFF0D3D1F)],
      status: ListingStatus.available,
      isNew: true,
    ),
    RecipientListing(
      id: '6',
      title: 'Bakery bread loaves',
      headerLabel: '20 Bread loaves · Golden Crust Bakery',
      donorName: 'Golden Crust Bakery',
      area: 'Patan',
      distanceKm: 2.1,
      minutesLeft: 50,
      listingType: ListingType.donateFree,
      foodCategory: FoodCategory.veg,
      quantity: 20,
      quantityUnit: 'Loaves',
      description:
      'End-of-day wholewheat and white bread loaves, unsold but freshly baked this morning.',
      pickupAddress: 'Patan Dhoka, Lalitpur',
      pickupInstructions: 'Front counter, mention Recipient app',
      headerGradient: [Color(0xFF6D4C41), Color(0xFF3E2723)],
      status: ListingStatus.available,
    ),
    RecipientListing(
      id: '7',
      title: 'Buffet leftover sweets box',
      headerLabel: 'Sweets box (10pc) · Himalayan Sweets',
      donorName: 'Himalayan Sweets House',
      area: 'Kalanki',
      distanceKm: 3.0,
      minutesLeft: 35,
      listingType: ListingType.discountedSale,
      foodCategory: FoodCategory.veg,
      quantity: 10,
      quantityUnit: 'Boxes',
      description:
      'Assorted traditional sweets left over from a festival order, boxed and ready for same-day pickup.',
      pickupAddress: 'Kalanki, Kathmandu',
      pickupInstructions: 'Ask at the billing counter',
      headerGradient: [Color(0xFFAD1457), Color(0xFF6A1B4D)],
      originalPrice: 900,
      discountedPrice: 300,
      discountPercent: 67,
      status: ListingStatus.available,
    ),
  ];

  static List<RecipientListing> filter(
      List<RecipientListing> source, {
        RecipientListingFilter filter = RecipientListingFilter.doneCompleted,
        String query = '',
      }) {
    final normalizedQuery = query.trim().toLowerCase();

    return source.where((listing) {
      final matchesQuery = normalizedQuery.isEmpty ||
          listing.title.toLowerCase().contains(normalizedQuery) ||
          listing.donorName.toLowerCase().contains(normalizedQuery) ||
          listing.area.toLowerCase().contains(normalizedQuery);

      if (!matchesQuery) return false;

      switch (filter) {
        case RecipientListingFilter.doneCompleted:
          return listing.status == ListingStatus.completed;
        case RecipientListingFilter.remaining:
          return listing.status == ListingStatus.available;
        case RecipientListingFilter.pending:
          return listing.status == ListingStatus.claimed;
      }
    }).toList();
  }
}