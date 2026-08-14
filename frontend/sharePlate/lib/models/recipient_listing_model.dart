import 'package:flutter/material.dart';

import 'donation_model.dart';

enum RecipientListingFilter { all, freeOnly, discounted, underThirtyMin }

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
    ),
  ];

  static List<RecipientListing> filter(
    List<RecipientListing> source, {
    RecipientListingFilter filter = RecipientListingFilter.all,
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
        case RecipientListingFilter.all:
          return true;
        case RecipientListingFilter.freeOnly:
          return listing.isFree;
        case RecipientListingFilter.discounted:
          return !listing.isFree;
        case RecipientListingFilter.underThirtyMin:
          return listing.minutesLeft < 30;
      }
    }).toList();
  }
}
