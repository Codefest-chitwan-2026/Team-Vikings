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

  static const List<ContributionItem> mockContributions = [
    ContributionItem(
      id: 'contrib_1',
      title: 'Rice with curry · 10 Plate',
      recipientName: 'Rampur Aasthaliya Org',
      recipientCategory: 'Community Kitchen',
      recipientAddress: 'Rampur Road, Chitwan',
      recipientPhone: '+977 9845012345',
      category: FoodCategory.veg,
      plates: 10,
      servesApprox: '15 people',
      status: DonationStatus.completed,
      dateAgo: '3 days ago',
      formattedDate: 'Aug 11, 2026 at 7:30 PM',
      pickupAddress: 'Himalayan Bistro, Ward 4, Narayangarh',
      pickupTime: '7:45 PM',
      deliveredTime: '8:15 PM',
      driverVolunteer: 'Bikash Adhikari (SharePlate Volunteer)',
      receiptNumber: 'SP-REC-2026-8812',
      co2SavedKg: 4.8,
      beneficiariesCount: 15,
      description:
          'Warm steamed basmati rice with paneer butter masala and mixed seasonal vegetable tarkari. Cleanly packaged in sealed aluminum containers.',
      bannerGradient: [Color(0xFF1EAA55), Color(0xFF0F6B35)],
    ),
    ContributionItem(
      id: 'contrib_2',
      title: 'Bakery Box Assortment · 9 units',
      recipientName: 'Aasha Foundation',
      recipientCategory: 'NGO',
      recipientAddress: 'Lazimpat, Kathmandu',
      recipientPhone: '+977 9841234567',
      category: FoodCategory.mixed,
      plates: 9,
      servesApprox: '20 children',
      status: DonationStatus.completed,
      dateAgo: '5 days ago',
      formattedDate: 'Aug 09, 2026 at 6:10 PM',
      pickupAddress: 'Sweet Delights Bakery, Lazimpat',
      pickupTime: '6:30 PM',
      deliveredTime: '7:00 PM',
      driverVolunteer: 'Priya Gurung',
      receiptNumber: 'SP-REC-2026-8794',
      co2SavedKg: 3.5,
      beneficiariesCount: 20,
      description:
          'Fresh artisanal croissants, cinnamon rolls, whole wheat muffins, and sandwich loaves from afternoon baking batch.',
      bannerGradient: [Color(0xFFE65100), Color(0xFFB71C1C)],
    ),
    ContributionItem(
      id: 'contrib_3',
      title: 'Wedding Feast Trays · 14 Trays',
      recipientName: 'Sneha Children Home',
      recipientCategory: 'Orphanage',
      recipientAddress: 'Sanepa, Lalitpur',
      recipientPhone: '+977 9851122334',
      category: FoodCategory.mixed,
      plates: 14,
      servesApprox: '45 people',
      status: DonationStatus.completed,
      dateAgo: '1 week ago',
      formattedDate: 'Aug 07, 2026 at 9:00 PM',
      pickupAddress: 'Royal Palace Banquet, Jawalakhel',
      pickupTime: '9:30 PM',
      deliveredTime: '10:00 PM',
      driverVolunteer: 'Deepak Sharma',
      receiptNumber: 'SP-REC-2026-8721',
      co2SavedKg: 18.2,
      beneficiariesCount: 45,
      description:
          'Surplus catering from evening wedding banquet. Includes pulao, dal makhani, chicken curry, naan, and gulab jamun.',
      bannerGradient: [Color(0xFFFB8C00), Color(0xFFD84315)],
    ),
    ContributionItem(
      id: 'contrib_4',
      title: 'Vegetable Biryani Pots · 8 Pots',
      recipientName: 'Gautam Buddha Fdn',
      recipientCategory: 'Community Kitchen',
      recipientAddress: 'Baluwatar, Kathmandu',
      recipientPhone: '+977 9801987654',
      category: FoodCategory.veg,
      plates: 8,
      servesApprox: '30 people',
      status: DonationStatus.completed,
      dateAgo: '2 weeks ago',
      formattedDate: 'July 31, 2026 at 2:00 PM',
      pickupAddress: 'Spice Garden, Thamel',
      pickupTime: '2:20 PM',
      deliveredTime: '2:50 PM',
      driverVolunteer: 'Santosh Tamang',
      receiptNumber: 'SP-REC-2026-8650',
      co2SavedKg: 11.4,
      beneficiariesCount: 30,
      description:
          'Aromatic Hyderabadi vegetable biryani with raita and salad. Kept in insulated hot pots ready for lunch distribution.',
      bannerGradient: [Color(0xFF43A047), Color(0xFF1B5E20)],
    ),
  ];
}
