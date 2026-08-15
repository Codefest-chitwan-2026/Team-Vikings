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
    this.donationItem,
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
  final DonationItem? donationItem;

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

  factory RecipientListing.fromDonationItem(DonationItem item, {double userLat = 27.7172, double userLng = 85.3240}) {
    final isFree = item.listingType == ListingType.donateFree;
    final int discount = (item.originalPrice != null && item.discountedPrice != null && item.originalPrice! > 0)
        ? (((item.originalPrice! - item.discountedPrice!) / item.originalPrice!) * 100).round()
        : 50;

    int minsLeft = 45;
    if (item.priorityExpiresAt != null) {
      final diff = item.priorityExpiresAt!.difference(DateTime.now()).inMinutes;
      if (diff > 0) minsLeft = diff;
    } else if (item.bestBefore != null) {
      final diff = item.bestBefore!.difference(DateTime.now()).inMinutes;
      if (diff > 0) minsLeft = diff;
    }

    ListingStatus listingStatus = ListingStatus.available;
    if (item.status == DonationStatus.ngoEnRoute) {
      listingStatus = ListingStatus.claimed;
    } else if (item.status == DonationStatus.completed) {
      listingStatus = ListingStatus.completed;
    }

    return RecipientListing(
      id: item.id,
      title: item.title,
      headerLabel: '${item.quantity} ${item.quantityUnit} · ${item.donorBusinessName ?? 'Verified Donor'}',
      donorName: item.donorBusinessName ?? 'Local Food Business',
      area: item.pickupAddress.split(',').first,
      distanceKm: 1.2,
      minutesLeft: minsLeft,
      listingType: item.listingType,
      foodCategory: item.category,
      quantity: item.quantity,
      quantityUnit: item.quantityUnit,
      description: item.description ?? 'Freshly prepared surplus food ready for immediate distribution.',
      pickupAddress: item.pickupAddress,
      pickupInstructions: 'Kitchen entrance, please show verification QR code.',
      headerGradient: isFree ? const [Color(0xFF1EAA55), Color(0xFF0F6B35)] : const [Color(0xFFE65100), Color(0xFFB71C1C)],
      originalPrice: item.originalPrice,
      discountedPrice: item.discountedPrice,
      discountPercent: isFree ? null : discount,
      status: listingStatus,
      isNew: true,
      donationItem: item,
    );
  }

  factory RecipientListing.fromJson(Map<String, dynamic> json) {
    final item = DonationItem.fromJson(json);
    return RecipientListing.fromDonationItem(item);
  }
}

class RecipientListingModel {
  static const organizationName = 'Aasha Foundation';

  static const stats = (
    mealsClaimed: 13,
    activeListings: 4,
    savedOnDeals: 'Rs 2.1k',
  );

  static const listings = <RecipientListing>[];

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