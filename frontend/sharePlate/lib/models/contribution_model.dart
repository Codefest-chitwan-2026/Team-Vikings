import 'package:flutter/material.dart';
import 'donation_model.dart';

class ContributionItem {
  final String id;
  final String title;
  final String recipientName;
  final String recipientCategory;
  final String recipientAddress;
  final String recipientPhone;
  final FoodCategory category;
  final int plates;
  final String servesApprox;
  final DonationStatus status;
  final String dateAgo;
  final String formattedDate;
  final String pickupAddress;
  final String pickupTime;
  final String deliveredTime;
  final String driverVolunteer;
  final String receiptNumber;
  final double co2SavedKg;
  final int beneficiariesCount;
  final String description;
  final List<Color> bannerGradient;
  final String? imagePath;

  const ContributionItem({
    required this.id,
    required this.title,
    required this.recipientName,
    required this.recipientCategory,
    required this.recipientAddress,
    required this.recipientPhone,
    required this.category,
    required this.plates,
    required this.servesApprox,
    required this.status,
    required this.dateAgo,
    required this.formattedDate,
    required this.pickupAddress,
    required this.pickupTime,
    required this.deliveredTime,
    required this.driverVolunteer,
    required this.receiptNumber,
    required this.co2SavedKg,
    required this.beneficiariesCount,
    required this.description,
    required this.bannerGradient,
    this.imagePath,
  });

  String get categoryLabel {
    switch (category) {
      case FoodCategory.veg:
        return 'Vegetarian';
      case FoodCategory.nonVeg:
        return 'Non-Vegetarian';
      case FoodCategory.mixed:
        return 'Mixed Platter';
    }
  }

  String get statusLabel {
    switch (status) {
      case DonationStatus.awaitingClaim:
        return 'Awaiting Claim';
      case DonationStatus.ngoEnRoute:
        return 'In Progress';
      case DonationStatus.completed:
        return 'Completed';
    }
  }

  factory ContributionItem.fromJson(Map<String, dynamic> json) {
    final rawCategory = (json['category'] ?? 'VEG').toString().toUpperCase();
    final FoodCategory cat = rawCategory.contains('NON')
        ? FoodCategory.nonVeg
        : (rawCategory.contains('MIX') ? FoodCategory.mixed : FoodCategory.veg);

    final rawStatus = (json['status'] ?? 'COMPLETED').toString().toUpperCase();
    DonationStatus donStatus = DonationStatus.completed;
    if (rawStatus.contains('AWAIT') || rawStatus.contains('AVAILABLE')) {
      donStatus = DonationStatus.awaitingClaim;
    } else if (rawStatus.contains('ROUTE') || rawStatus.contains('PROGRESS') || rawStatus.contains('CLAIMED')) {
      donStatus = DonationStatus.ngoEnRoute;
    }

    String formatted = 'Recently';
    String ago = 'Recently';
    if (json['created_at'] != null) {
      try {
        final d = DateTime.parse(json['created_at'].toString());
        formatted = '${_monthName(d.month)} ${d.day}, ${d.year}';
        final diff = DateTime.now().difference(d);
        if (diff.inDays > 0) {
          ago = '${diff.inDays} days ago';
        } else if (diff.inHours > 0) {
          ago = '${diff.inHours} hr ago';
        } else {
          ago = 'Just now';
        }
      } catch (_) {}
    }

    return ContributionItem(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? 'Food Donation',
      recipientName: json['recipient_name'] ?? 'Verified NGO',
      recipientCategory: json['recipient_category'] ?? 'Community Kitchen',
      recipientAddress: json['recipient_address'] ?? 'Kathmandu',
      recipientPhone: json['recipient_phone'] ?? '',
      category: cat,
      plates: int.tryParse(json['plates']?.toString() ?? '10') ?? 10,
      servesApprox: json['serves_approx'] ?? '${json['plates'] ?? 10} portions',
      status: donStatus,
      dateAgo: ago,
      formattedDate: formatted,
      pickupAddress: json['pickup_address'] ?? 'Kathmandu',
      pickupTime: json['pickup_time'] ?? '7:00 PM',
      deliveredTime: json['delivered_time'] ?? '7:45 PM',
      driverVolunteer: json['driver_volunteer'] ?? 'SharePlate Volunteer',
      receiptNumber: json['receipt_number'] ?? 'SP-REC-2026-${json['id'] ?? 1001}',
      co2SavedKg: double.tryParse(json['co2_saved_kg']?.toString() ?? '4.8') ?? 4.8,
      beneficiariesCount: int.tryParse(json['beneficiaries_count']?.toString() ?? '15') ?? 15,
      description: json['description'] ?? 'Surplus meal package delivered to community shelter.',
      bannerGradient: _getGradientForCategory(cat),
      imagePath: json['image']?.toString(),
    );
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  static List<Color> _getGradientForCategory(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return const [Color(0xFF1EAA55), Color(0xFF0F6B35)];
      case FoodCategory.nonVeg:
        return const [Color(0xFF8E24AA), Color(0xFF4A148C)];
      case FoodCategory.mixed:
        return const [Color(0xFFE65100), Color(0xFFB71C1C)];
    }
  }

  static const List<ContributionItem> mockContributions = [];
}
