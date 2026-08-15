import 'package:flutter/material.dart';

class NearbyNgo {
  final String id;
  final String name;
  final String category; // 'NGO', 'Orphanage', 'Elderly Home', 'Community Kitchen', 'Others'
  final String address;
  final double distanceKm;
  final String phoneNumber;
  final String email;
  final String contactPerson;
  final String panNumber;
  final bool isVerified;
  final int totalMealsReceived;
  final int peopleSupported;
  final String description;
  final List<String> currentNeeds;
  final Color themeColor;
  final List<Color> bannerGradient;
  final double latitude;
  final double longitude;
  final String urgencyLevel; // 'High', 'Moderate', 'Standard'

  const NearbyNgo({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.distanceKm,
    required this.phoneNumber,
    required this.email,
    required this.contactPerson,
    required this.panNumber,
    required this.isVerified,
    required this.totalMealsReceived,
    required this.peopleSupported,
    required this.description,
    required this.currentNeeds,
    required this.themeColor,
    required this.bannerGradient,
    required this.latitude,
    required this.longitude,
    this.urgencyLevel = 'Standard',
  });

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';
  String get area => address;
  String get focusArea => category;
  String get phone => phoneNumber;

  factory NearbyNgo.fromJson(Map<String, dynamic> json) {
    final orgName = (json['organization_name'] ?? json['name'] ?? 'Verified NGO').toString();
    final orgType = (json['organization_type'] ?? json['category'] ?? 'NGO').toString();
    final address = (json['address'] ?? 'Kathmandu').toString();
    final dist = double.tryParse(json['distance_km']?.toString() ?? '1.2') ?? 1.2;
    final phone = (json['phone_number'] ?? json['phone'] ?? json['phone_num'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final contact = (json['contact_name'] ?? json['contactPerson'] ?? 'Coordinator').toString();
    final pan = (json['registration_number'] ?? json['panNumber'] ?? '').toString();
    final status = (json['verification_status'] ?? '').toString().toUpperCase();
    final isVerified = status == 'VERIFIED' || json['isVerified'] == true;
    final lat = double.tryParse(json['latitude']?.toString() ?? '27.7172') ?? 27.7172;
    final lng = double.tryParse(json['longitude']?.toString() ?? '85.3240') ?? 85.3240;

    return NearbyNgo(
      id: (json['id'] ?? 'ngo-${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: orgName,
      category: orgType,
      address: address,
      distanceKm: dist,
      phoneNumber: phone,
      email: email,
      contactPerson: contact,
      panNumber: pan,
      isVerified: isVerified,
      totalMealsReceived: int.tryParse(json['total_meals_received']?.toString() ?? '1200') ?? 1200,
      peopleSupported: int.tryParse(json['people_supported']?.toString() ?? '150') ?? 150,
      description: json['description']?.toString() ?? 'Registered NGO dedicated to food distribution and community support.',
      currentNeeds: json['current_needs'] is List
          ? (json['current_needs'] as List).map((e) => e.toString()).toList()
          : const ['Cooked dinner meals', 'Bakery surplus', 'Dry food rations'],
      themeColor: const Color(0xFFF5E8F6),
      bannerGradient: _getGradient(orgType),
      latitude: lat,
      longitude: lng,
      urgencyLevel: json['urgency_level']?.toString() ?? 'High',
    );
  }

  static List<Color> _getGradient(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('orphan')) {
      return const [Color(0xFFFB8C00), Color(0xFFE65100)];
    } else if (lower.contains('elder')) {
      return const [Color(0xFF3949AB), Color(0xFF1A237E)];
    } else if (lower.contains('kitchen')) {
      return const [Color(0xFF1EAA55), Color(0xFF0F6B35)];
    }
    return const [Color(0xFF8E24AA), Color(0xFF4A148C)];
  }

  static const List<NearbyNgo> mockNgos = [];
}
