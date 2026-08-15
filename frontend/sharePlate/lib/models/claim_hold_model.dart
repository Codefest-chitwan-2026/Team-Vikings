class ClaimHoldModel {
  final int id;
  final int donationId;
  final int ngoId;
  final String status;
  final DateTime expiresAt;
  final int secondsRemaining;

  ClaimHoldModel({
    required this.id,
    required this.donationId,
    required this.ngoId,
    required this.status,
    required this.expiresAt,
    required this.secondsRemaining,
  });

  bool get isActive => status == 'ACTIVE' && secondsRemaining > 0;

  factory ClaimHoldModel.fromJson(Map<String, dynamic> json) {
    DateTime exp = DateTime.now().add(const Duration(minutes: 5));
    if (json['expires_at'] != null) {
      try {
        exp = DateTime.parse(json['expires_at'].toString());
      } catch (_) {}
    }

    return ClaimHoldModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      donationId: int.tryParse(json['donation']?.toString() ?? json['donation_id']?.toString() ?? '0') ?? 0,
      ngoId: int.tryParse(json['ngo']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'ACTIVE',
      expiresAt: exp,
      secondsRemaining: int.tryParse(json['seconds_remaining']?.toString() ?? '300') ?? 300,
    );
  }
}

class PickupQRPayload {
  final String claimReference;
  final String qrCode;
  final String manualCode;
  final DateTime expiresAt;
  final bool isExpired;
  final String ticketType;
  final String foodSummary;
  final String? claimedBy;
  final String pickupWindow;
  final String address;
  final String contact;
  final int donationId;

  PickupQRPayload({
    required this.claimReference,
    required this.qrCode,
    required this.manualCode,
    required this.expiresAt,
    required this.isExpired,
    required this.ticketType,
    required this.foodSummary,
    this.claimedBy,
    required this.pickupWindow,
    required this.address,
    required this.contact,
    required this.donationId,
  });

  factory PickupQRPayload.fromJson(Map<String, dynamic> json) {
    DateTime exp = DateTime.now().add(const Duration(hours: 2));
    if (json['expires_at'] != null) {
      try {
        exp = DateTime.parse(json['expires_at'].toString());
      } catch (_) {}
    }

    return PickupQRPayload(
      claimReference: json['claim_reference'] ?? 'CLM-0000',
      qrCode: json['qr_code'] ?? '',
      manualCode: json['manual_code'] ?? '',
      expiresAt: exp,
      isExpired: json['is_expired'] == true,
      ticketType: json['ticket_type'] ?? 'NGO_CLAIM',
      foodSummary: json['food_summary'] ?? 'Surplus Food',
      claimedBy: json['claimed_by']?.toString(),
      pickupWindow: json['pickup_window'] ?? '',
      address: json['address'] ?? 'Kathmandu',
      contact: json['contact'] ?? '',
      donationId: int.tryParse(json['donation_id']?.toString() ?? '0') ?? 0,
    );
  }
}
