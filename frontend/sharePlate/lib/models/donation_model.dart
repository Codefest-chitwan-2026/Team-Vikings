enum FoodCategory { veg, nonVeg, mixed }

extension FoodCategoryX on FoodCategory {
  String get label => switch (this) {
    FoodCategory.veg => 'Veg',
    FoodCategory.nonVeg => 'Non-veg',
    FoodCategory.mixed => 'Mixed',
  };
}

enum ListingType { donateFree, discountedSale }

enum ListingStatus { available, claimed, completed, expired, cancelled }

enum DonationStatus { awaitingClaim, ngoEnRoute, completed }

enum DonationCardAction { edit, boost, track, cancel, receipt, repeat }

class DonationAction {
  const DonationAction({
    required this.label,
    required this.action,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final DonationCardAction action;
  final bool isPrimary;
  final bool isDestructive;
}

class DonationItem {
  final String id;
  final String postedAgo;
  final String title;
  final FoodCategory category;
  final int quantity;
  final String quantityUnit;
  final String servesApprox;
  final DonationStatus status;
  final bool isActive;
  final String? recipient;
  final String? recipientPhone;
  final String? recipientAddress;
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String pickupWindow;
  final ListingType listingType;
  final double? originalPrice;
  final double? discountedPrice;
  final String? imagePath;
  final String? description;
  final String? receiptNumber;
  final String? completedDate;
  final String? donorBusinessName;
  final String? qrCode;
  final String? manualCode;
  final DateTime? bestBefore;
  final DateTime? priorityExpiresAt;
  final bool ngoPriorityActive;
  final int prioritySecondsRemaining;
  final Map<String, dynamic>? rawJson;

  const DonationItem({
    required this.id,
    required this.postedAgo,
    required this.title,
    this.category = FoodCategory.veg,
    this.quantity = 10,
    this.quantityUnit = 'Plates',
    this.servesApprox = '12-15 people',
    required this.status,
    required this.isActive,
    this.recipient,
    this.recipientPhone,
    this.recipientAddress,
    this.pickupAddress = 'Lazimpat, Kathmandu',
    this.pickupLatitude = 27.7215,
    this.pickupLongitude = 85.3206,
    this.pickupWindow = '30 minutes',
    this.listingType = ListingType.donateFree,
    this.originalPrice,
    this.discountedPrice,
    this.imagePath,
    this.description,
    this.receiptNumber,
    this.completedDate,
    this.donorBusinessName,
    this.qrCode,
    this.manualCode,
    this.bestBefore,
    this.priorityExpiresAt,
    this.ngoPriorityActive = false,
    this.prioritySecondsRemaining = 0,
    this.rawJson,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'AVAILABLE').toString().toUpperCase();
    final rawFoodType = (json['food_type'] ?? 'VEG').toString().toUpperCase();
    final rawListingType = (json['listing_type'] ?? 'DONATION').toString().toUpperCase();

    final FoodCategory cat = rawFoodType.contains('NON')
        ? FoodCategory.nonVeg
        : (rawFoodType.contains('MIX') ? FoodCategory.mixed : FoodCategory.veg);

    final ListingType listType = (rawListingType == 'FLASH_SALE' || rawListingType == 'DISCOUNTEDSALE')
        ? ListingType.discountedSale
        : ListingType.donateFree;

    DonationStatus donStatus;
    bool active;
    if (rawStatus == 'AVAILABLE') {
      donStatus = DonationStatus.awaitingClaim;
      active = true;
    } else if (rawStatus == 'CLAIMED' || rawStatus == 'RESERVED' || rawStatus == 'NGO_EN_ROUTE') {
      donStatus = DonationStatus.ngoEnRoute;
      active = true;
    } else {
      donStatus = DonationStatus.completed;
      active = false;
    }

    final claimMap = json['claim'] is Map<String, dynamic> ? json['claim'] as Map<String, dynamic> : null;
    final ngoName = claimMap?['ngo_name'] ?? claimMap?['ngo_details']?['organization_name'];
    final ngoPhone = claimMap?['ngo_details']?['phone'] ?? claimMap?['volunteer_phone'];
    final ngoAddress = claimMap?['ngo_details']?['address'];

    String? ticketQr = json['qr_code']?.toString();
    String? manualCode = json['manual_code']?.toString();

    if (claimMap?['pickup_ticket'] is Map<String, dynamic>) {
      ticketQr ??= claimMap!['pickup_ticket']['qr_code']?.toString();
    }
    if (json['pickup_ticket'] is Map<String, dynamic>) {
      ticketQr ??= json['pickup_ticket']['qr_code']?.toString();
    }

    final detailMap = json['listing_detail'] is Map<String, dynamic>
        ? json['listing_detail'] as Map<String, dynamic>
        : null;

    String pickupWin = '45 minutes';
    if (detailMap != null && detailMap['pickup_window_start'] != null && detailMap['pickup_window_end'] != null) {
      try {
        final start = DateTime.parse(detailMap['pickup_window_start'].toString());
        final end = DateTime.parse(detailMap['pickup_window_end'].toString());
        final diff = end.difference(start).inMinutes;
        pickupWin = '$diff minutes';
      } catch (_) {}
    }

    DateTime? bestBeforeDate;
    if (json['best_before'] != null) {
      try {
        bestBeforeDate = DateTime.parse(json['best_before'].toString());
      } catch (_) {}
    }

    DateTime? priorityExpiry;
    if (json['ngo_priority_expires_at'] != null) {
      try {
        priorityExpiry = DateTime.parse(json['ngo_priority_expires_at'].toString());
      } catch (_) {}
    }

    final businessName = json['donor_business_name']?.toString();
    final photo = json['food_photo'] ?? json['image'] ?? json['imagePath'];

    return DonationItem(
      id: (json['id'] ?? '').toString(),
      postedAgo: json['created_at'] != null ? _formatDateAgo(json['created_at'].toString()) : 'Recently',
      title: json['title'] ?? 'Food Donation',
      category: cat,
      quantity: (double.tryParse(json['quantity']?.toString() ?? '10') ?? 10).toInt(),
      quantityUnit: json['quantity_unit'] ?? 'Plates',
      servesApprox: json['people_served'] != null
          ? '${json['people_served']} people'
          : '${json['quantity'] ?? 10} portions',
      status: donStatus,
      isActive: active,
      recipient: ngoName?.toString(),
      recipientPhone: ngoPhone?.toString(),
      recipientAddress: ngoAddress?.toString(),
      pickupAddress: json['pickup_address'] ?? 'Kathmandu',
      pickupLatitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 27.7215,
      pickupLongitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 85.3206,
      pickupWindow: pickupWin,
      listingType: listType,
      originalPrice: double.tryParse(json['price']?.toString() ?? ''),
      discountedPrice: double.tryParse(json['flash_sale_price']?.toString() ?? ''),
      imagePath: photo?.toString(),
      description: json['description']?.toString(),
      receiptNumber: json['receipt_number']?.toString() ?? 'SP-DON-2026-${json['id'] ?? 1001}',
      completedDate: json['updated_at']?.toString(),
      donorBusinessName: businessName,
      qrCode: ticketQr,
      manualCode: manualCode,
      bestBefore: bestBeforeDate,
      priorityExpiresAt: priorityExpiry,
      ngoPriorityActive: json['ngo_priority_active'] == true,
      prioritySecondsRemaining: int.tryParse(json['priority_seconds_remaining']?.toString() ?? '0') ?? 0,
      rawJson: json,
    );
  }

  static String _formatDateAgo(String iso) {
    try {
      final date = DateTime.parse(iso);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Recently';
    }
  }

  DonationItem copyWith({
    String? id,
    String? postedAgo,
    String? title,
    FoodCategory? category,
    int? quantity,
    String? quantityUnit,
    String? servesApprox,
    DonationStatus? status,
    bool? isActive,
    String? recipient,
    String? recipientPhone,
    String? recipientAddress,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupWindow,
    ListingType? listingType,
    double? originalPrice,
    double? discountedPrice,
    String? imagePath,
    String? description,
    String? receiptNumber,
    String? completedDate,
    String? donorBusinessName,
    String? qrCode,
    String? manualCode,
    DateTime? bestBefore,
    DateTime? priorityExpiresAt,
    bool? ngoPriorityActive,
    int? prioritySecondsRemaining,
    Map<String, dynamic>? rawJson,
  }) {
    return DonationItem(
      id: id ?? this.id,
      postedAgo: postedAgo ?? this.postedAgo,
      title: title ?? this.title,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      servesApprox: servesApprox ?? this.servesApprox,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      recipient: recipient ?? this.recipient,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupWindow: pickupWindow ?? this.pickupWindow,
      listingType: listingType ?? this.listingType,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      completedDate: completedDate ?? this.completedDate,
      donorBusinessName: donorBusinessName ?? this.donorBusinessName,
      qrCode: qrCode ?? this.qrCode,
      manualCode: manualCode ?? this.manualCode,
      bestBefore: bestBefore ?? this.bestBefore,
      priorityExpiresAt: priorityExpiresAt ?? this.priorityExpiresAt,
      ngoPriorityActive: ngoPriorityActive ?? this.ngoPriorityActive,
      prioritySecondsRemaining: prioritySecondsRemaining ?? this.prioritySecondsRemaining,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  List<DonationAction> get actions {
    switch (status) {
      case DonationStatus.awaitingClaim:
        return const [
          DonationAction(label: 'Edit', action: DonationCardAction.edit),
          DonationAction(
            label: 'Boost visibility',
            action: DonationCardAction.boost,
            isPrimary: true,
          ),
        ];
      case DonationStatus.ngoEnRoute:
        return const [
          DonationAction(label: 'Track', action: DonationCardAction.track),
          DonationAction(
            label: 'Cancel',
            action: DonationCardAction.cancel,
            isDestructive: true,
          ),
        ];
      case DonationStatus.completed:
        return const [
          DonationAction(label: 'Receipt', action: DonationCardAction.receipt),
          DonationAction(
            label: 'Repeat listing',
            action: DonationCardAction.repeat,
            isPrimary: true,
          ),
        ];
    }
  }

  String get categoryLabel {
    switch (category) {
      case FoodCategory.veg:
        return 'Veg';
      case FoodCategory.nonVeg:
        return 'Non-Veg';
      case FoodCategory.mixed:
        return 'Mixed';
    }
  }

  String get statusLabel {
    switch (status) {
      case DonationStatus.awaitingClaim:
        return 'Awaiting claim';
      case DonationStatus.ngoEnRoute:
        return 'NGO en route';
      case DonationStatus.completed:
        return 'Completed';
    }
  }
}

class TrackStep {
  const TrackStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
}

class DonationModel {
  static const activeDonations = [
    DonationItem(
      id: '1',
      postedAgo: '12 min ago',
      title: 'Rice bowl with curry · 10 Plates',
      category: FoodCategory.veg,
      quantity: 10,
      quantityUnit: 'Plates',
      servesApprox: '15 people',
      status: DonationStatus.awaitingClaim,
      isActive: true,
      pickupAddress: 'Himalayan Bites Cafe, Lazimpat, Kathmandu',
      pickupLatitude: 27.7215,
      pickupLongitude: 85.3206,
      pickupWindow: '30 minutes',
      listingType: ListingType.donateFree,
      description: 'Hot steamed basmati rice with paneer butter masala and daal tadka.',
      receiptNumber: 'SP-DON-2026-9901',
    ),
    DonationItem(
      id: '2',
      postedAgo: '1 hr ago',
      title: 'Bakery box (6pc) · 9 units',
      category: FoodCategory.mixed,
      quantity: 9,
      quantityUnit: 'Boxes',
      servesApprox: '18 people',
      status: DonationStatus.ngoEnRoute,
      isActive: true,
      recipient: 'Rampur Aanathalaya Org',
      recipientPhone: '+977 9845012345',
      recipientAddress: 'Rampur Road, Chitwan',
      pickupAddress: 'Sweet Delights Bakery, Thamel, Kathmandu',
      pickupLatitude: 27.7154,
      pickupLongitude: 85.3123,
      pickupWindow: '45 minutes',
      listingType: ListingType.donateFree,
      description: 'Fresh baked croissants, rolls, and vanilla muffins from today.',
      receiptNumber: 'SP-DON-2026-9884',
    ),
  ];

  static const pastDonations = [
    DonationItem(
      id: '4',
      postedAgo: '3 days ago',
      title: 'Rice with curry · 10 Plates',
      category: FoodCategory.veg,
      quantity: 10,
      quantityUnit: 'Plates',
      servesApprox: '15 people',
      status: DonationStatus.completed,
      isActive: false,
      recipient: 'Rampur Aasthaliya Org',
      recipientPhone: '+977 9845012345',
      recipientAddress: 'Rampur, Chitwan',
      pickupAddress: 'Himalayan Bites Cafe, Narayangarh',
      pickupLatitude: 27.6852,
      pickupLongitude: 85.3124,
      pickupWindow: '30 minutes',
      listingType: ListingType.donateFree,
      description: 'Rice, mixed vegetables and lentils prepared for lunchtime.',
      receiptNumber: 'SP-REC-2026-8794',
      completedDate: 'Aug 09, 2026',
    ),
  ];

  static const trackSteps = [
    TrackStep(
      title: 'Listing posted',
      subtitle: '6:42 PM · You posted this donation',
      isCompleted: true,
    ),
    TrackStep(
      title: 'Claimed by NGO',
      subtitle: '6:48 PM · Rampur Aanathalaya Org accepted',
      isCompleted: true,
    ),
    TrackStep(
      title: 'Volunteer en route',
      subtitle: '6:55 PM · Pickup in progress',
      isCompleted: true,
    ),
    TrackStep(
      title: 'Handover confirmed',
      subtitle: 'Pending · Photo confirmation on arrival',
      isCompleted: false,
    ),
  ];
}
