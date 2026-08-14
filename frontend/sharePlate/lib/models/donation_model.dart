enum FoodCategory { veg, nonVeg, mixed }

enum ListingType { donateFree, discountedSale }

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
  });

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
    DonationItem(
      id: '3',
      postedAgo: '3 days ago',
      title: 'Wedding catering trays · 14 trays',
      category: FoodCategory.mixed,
      quantity: 14,
      quantityUnit: 'Trays',
      servesApprox: '45 people',
      status: DonationStatus.completed,
      isActive: true,
      recipient: 'Aasha Foundation',
      recipientPhone: '+977 9841234567',
      recipientAddress: 'Lazimpat, Kathmandu',
      pickupAddress: 'Royal Palace Events, Baluwatar, Kathmandu',
      pickupLatitude: 27.7289,
      pickupLongitude: 85.3340,
      pickupWindow: '1 hour',
      listingType: ListingType.donateFree,
      description: 'Grand wedding catering surplus: Pulao, mutton curry, paneer, and naan.',
      receiptNumber: 'SP-REC-2026-8812',
      completedDate: 'Aug 11, 2026',
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
    DonationItem(
      id: '5',
      postedAgo: '1 week ago',
      title: 'Vegetable Biryani Pots · 8 Pots',
      category: FoodCategory.veg,
      quantity: 8,
      quantityUnit: 'Pots',
      servesApprox: '30 people',
      status: DonationStatus.completed,
      isActive: false,
      recipient: 'Gautam Buddha Fdn',
      recipientPhone: '+977 9801987654',
      recipientAddress: 'Baluwatar, Kathmandu',
      pickupAddress: 'Spice Garden, Thamel, Kathmandu',
      pickupLatitude: 27.7104,
      pickupLongitude: 85.3487,
      pickupWindow: '45 minutes',
      listingType: ListingType.donateFree,
      description: 'Fragrant vegetable biryani cooked fresh for lunch banquet.',
      receiptNumber: 'SP-REC-2026-8721',
      completedDate: 'Aug 07, 2026',
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
