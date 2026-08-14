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
  const DonationItem({
    required this.id,
    required this.postedAgo,
    required this.title,
    required this.status,
    required this.isActive,
    this.recipient,
  });

  final String id;
  final String postedAgo;
  final String title;
  final DonationStatus status;
  final bool isActive;
  final String? recipient;

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
      status: DonationStatus.awaitingClaim,
      isActive: true,
    ),
    DonationItem(
      id: '2',
      postedAgo: '1 hr ago',
      title: 'Bakery box (6pc) · 9 units',
      status: DonationStatus.ngoEnRoute,
      isActive: true,
      recipient: 'Rampur Aanathalaya Org',
    ),
    DonationItem(
      id: '3',
      postedAgo: '3 days ago',
      title: 'Wedding catering trays · 14 trays',
      status: DonationStatus.completed,
      isActive: true,
    ),
  ];

  static const pastDonations = [
    DonationItem(
      id: '4',
      postedAgo: '3 days ago',
      title: 'Rice with curry · 10 Plates',
      status: DonationStatus.completed,
      isActive: false,
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
