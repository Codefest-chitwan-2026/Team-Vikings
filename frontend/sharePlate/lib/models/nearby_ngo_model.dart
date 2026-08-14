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

  static const List<NearbyNgo> mockNgos = [
    NearbyNgo(
      id: 'ngo_1',
      name: 'Aasha Foundation',
      category: 'NGO',
      address: 'Lazimpat, Kathmandu',
      distanceKm: 0.8,
      phoneNumber: '+977 9841234567',
      email: 'contact@aashafoundation.org.np',
      contactPerson: 'Suman Shrestha (Director)',
      panNumber: '601298451',
      isVerified: true,
      totalMealsReceived: 1240,
      peopleSupported: 350,
      description:
          'Aasha Foundation is dedicated to zero food waste and daily hunger alleviation across the Kathmandu Valley, serving underprivileged children, day laborers, and elderly shelters.',
      currentNeeds: [
        'Need 35+ dinner portions daily',
        'Staple cooked meals (rice, lentils, vegetables)',
        'Bakery items for morning breakfast'
      ],
      themeColor: Color(0xFFF5E8F6),
      bannerGradient: [Color(0xFF8E24AA), Color(0xFF4A148C)],
      latitude: 27.7215,
      longitude: 85.3206,
      urgencyLevel: 'High',
    ),
    NearbyNgo(
      id: 'ngo_2',
      name: 'Gautam Buddha Foundation',
      category: 'Community Kitchen',
      address: 'Baluwatar, Kathmandu',
      distanceKm: 1.4,
      phoneNumber: '+977 9801987654',
      email: 'info@gautambuddhafdn.org',
      contactPerson: 'Ramesh Adhikari',
      panNumber: '602384729',
      isVerified: true,
      totalMealsReceived: 890,
      peopleSupported: 220,
      description:
          'Operating an open community kitchen supplying nutritious hot meals for hospital visitors, homeless shelters, and low-income families in Baluwatar.',
      currentNeeds: [
        'Surplus cooked catering rice & curry',
        'Packed boxed meals',
        'Dairy & bakery surplus'
      ],
      themeColor: Color(0xFFE5F4EA),
      bannerGradient: [Color(0xFF1EAA55), Color(0xFF0F6B35)],
      latitude: 27.7289,
      longitude: 85.3340,
      urgencyLevel: 'High',
    ),
    NearbyNgo(
      id: 'ngo_3',
      name: 'Sneha Children Home',
      category: 'Orphanage',
      address: 'Sanepa, Lalitpur',
      distanceKm: 2.3,
      phoneNumber: '+977 9851122334',
      email: 'help@snehachildren.org',
      contactPerson: 'Sneha Thapa',
      panNumber: '603991283',
      isVerified: true,
      totalMealsReceived: 1650,
      peopleSupported: 65,
      description:
          'A registered residential care home providing shelter, healthcare, and education for 65 orphaned and destitute children in Lalitpur.',
      currentNeeds: [
        'Fresh fruits and bread/pastries',
        'Cooked lunch/dinner portions',
        'Packaged snacks & juices'
      ],
      themeColor: Color(0xFFFFF3E0),
      bannerGradient: [Color(0xFFFB8C00), Color(0xFFE65100)],
      latitude: 27.6852,
      longitude: 85.3124,
      urgencyLevel: 'Moderate',
    ),
    NearbyNgo(
      id: 'ngo_4',
      name: 'Matribhumi Elderly Sanctuary',
      category: 'Elderly Home',
      address: 'Pashupati Area, Kathmandu',
      distanceKm: 3.1,
      phoneNumber: '+977 9849988776',
      email: 'care@matribhumisenior.org',
      contactPerson: 'Kiran KC',
      panNumber: '604817263',
      isVerified: true,
      totalMealsReceived: 720,
      peopleSupported: 48,
      description:
          'Caring for senior citizens without family support. Providing gentle, digestible vegetarian food, medical care, and continuous support.',
      currentNeeds: [
        'Soft vegetarian meals (Khichdi, soup, boiled veggies)',
        'Dairy products (milk, curd)',
        'Fresh seasonal fruits'
      ],
      themeColor: Color(0xFFE8EAF6),
      bannerGradient: [Color(0xFF3949AB), Color(0xFF1A237E)],
      latitude: 27.7104,
      longitude: 85.3487,
      urgencyLevel: 'Standard',
    ),
    NearbyNgo(
      id: 'ngo_5',
      name: 'Nepal Youth Food Bank',
      category: 'NGO',
      address: 'Thamel, Kathmandu',
      distanceKm: 1.1,
      phoneNumber: '+977 9812345678',
      email: 'youthfoodbank@nepal.org',
      contactPerson: 'Prashant Maharjan',
      panNumber: '605128374',
      isVerified: true,
      totalMealsReceived: 2100,
      peopleSupported: 500,
      description:
          'Youth-led food distribution network collecting commercial surplus from hotels, restaurants, and bakeries for distribution in squatter settlements.',
      currentNeeds: [
        'Any bulk cooked meal portions',
        'Pre-packed sandwiches and pastries',
        'Leftover party trays'
      ],
      themeColor: Color(0xFFE0F2F1),
      bannerGradient: [Color(0xFF00897B), Color(0xFF004D40)],
      latitude: 27.7154,
      longitude: 85.3123,
      urgencyLevel: 'High',
    ),
  ];
}
