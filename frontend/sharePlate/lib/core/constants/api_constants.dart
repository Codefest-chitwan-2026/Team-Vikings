import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Configurable base host for easy testing on emulator, real device, or local backend.
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    try {
      if (Platform.isAndroid) {
        // Android Emulator loops back to host machine via 10.0.2.2
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Fallback if Platform is not supported
    }
    return 'http://127.0.0.1:8000';
  }

  // Auth endpoints matching Django authentication app URLs
  static String get login => '$baseUrl/api/auth/login/';
  static String get logout => '$baseUrl/api/auth/logout/';
  static String get registerCustomer => '$baseUrl/api/auth/register/customer/';
  static String get registerBusiness => '$baseUrl/api/auth/register/business/';
  static String get registerNgo => '$baseUrl/api/auth/register/ngo/';
  static String get registerUser => '$baseUrl/api/auth/register/user/';

  // Profiles endpoints
  static String get profileMe => '$baseUrl/api/profiles/me/';
  static String get profileDocuments => '$baseUrl/api/profiles/documents/';
  static String get nearbyNgos => '$baseUrl/api/profiles/nearby-ngos/';

  // Donations endpoints
  static String get donations => '$baseUrl/api/donations/';
  static String donationDetail(dynamic id) => '$baseUrl/api/donations/$id/';
  static String get ngoPriority => '$baseUrl/api/donations/ngo_priority/';
  static String get flashSales => '$baseUrl/api/donations/flash_sales/';
  static String claimDonation(dynamic id) => '$baseUrl/api/donations/$id/claim/';
  static String reserveDonation(dynamic id) => '$baseUrl/api/donations/$id/reserve/';
  static String convertToFlashSale(dynamic id) => '$baseUrl/api/donations/$id/convert_to_flash_sale/';
  static String cancelDonation(dynamic id) => '$baseUrl/api/donations/$id/cancel/';
  static String get verifyPickup => '$baseUrl/api/donations/verify_pickup/';
  static String get claims => '$baseUrl/api/claims/';
  static String get reservations => '$baseUrl/api/reservations/';

  // Orders endpoints
  static String get orders => '$baseUrl/api/orders/';
  static String orderDetail(dynamic id) => '$baseUrl/api/orders/$id/';

  // Sponsorships endpoints
  static String get sponsorshipItems => '$baseUrl/api/sponsorship-items/';
  static String get sponsorships => '$baseUrl/api/sponsorships/';

  // Contributions endpoints
  static String get contributions => '$baseUrl/api/contributions/';
  static String contributionDetail(dynamic id) => '$baseUrl/api/contributions/$id/';

  // Notifications endpoints
  static String get notifications => '$baseUrl/api/notifications/';
  static String notificationRead(dynamic id) => '$baseUrl/api/notifications/$id/read/';
  static String get notificationReadAll => '$baseUrl/api/notifications/read-all/';
  static String get notificationSettings => '$baseUrl/api/notification-settings/';

  // Listing Flow endpoints
  static String get listingFlow => '$baseUrl/api/listing-flow/';
  static String listingFlowDetail(dynamic id) => '$baseUrl/api/listing-flow/$id/detail/';
  static String listingFlowListingDetail(dynamic id) => '$baseUrl/api/listing-flow/$id/listing-detail/';
  static String listingFlowUpdate(dynamic id) => '$baseUrl/api/listing-flow/$id/listing-update/';
  static String listingFlowAdjustPrice(dynamic id) => '$baseUrl/api/listing-flow/$id/adjust-price/';
  static String listingFlowKeepDonationOnly(dynamic id) => '$baseUrl/api/listing-flow/$id/keep-donation-only/';
  static String listingFlowProcessPriorityExpiry(dynamic id) => '$baseUrl/api/listing-flow/$id/process-priority-expiry/';
  static String get claimHolds => '$baseUrl/api/claim-holds/';
  static String claimHoldConfirm(dynamic id) => '$baseUrl/api/claim-holds/$id/confirm/';
  static String claimHoldCancel(dynamic id) => '$baseUrl/api/claim-holds/$id/cancel/';
  static String get pickupQr => '$baseUrl/api/pickup-qr/';
  static String pickupQrByClaim(dynamic claimId) => '$baseUrl/api/pickup-qr/by-claim/$claimId/';
  static String pickupQrByTicket(dynamic ticketId) => '$baseUrl/api/pickup-qr/by-ticket/$ticketId/';
  static String get verifyPickupEndpoint => '$baseUrl/api/verify-pickup/';
  static String verifyPickupExpected(String code) => '$baseUrl/api/verify-pickup/expected/$code/';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
