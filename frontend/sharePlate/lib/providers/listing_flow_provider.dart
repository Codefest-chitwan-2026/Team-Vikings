import 'package:flutter/material.dart';
import '../core/errors/error_sanitizer.dart';
import '../models/claim_hold_model.dart';
import '../models/donation_model.dart';
import '../repositories/listing_flow_repository.dart';

class ListingFlowProvider extends ChangeNotifier {
  final IListingFlowRepository _listingFlowRepository;

  ListingFlowProvider({IListingFlowRepository? listingFlowRepository})
      : _listingFlowRepository = listingFlowRepository ?? ListingFlowRepository();

  DonationItem? _currentDonationDetail;
  Map<String, dynamic>? _currentListingUpdate;
  final List<ClaimHoldModel> _activeHolds = [];
  PickupQRPayload? _currentQrPayload;
  bool _isLoading = false;
  String? _errorMessage;

  DonationItem? get currentDonationDetail => _currentDonationDetail;
  Map<String, dynamic>? get currentListingUpdate => _currentListingUpdate;
  List<ClaimHoldModel> get activeHolds => List.unmodifiable(_activeHolds);
  PickupQRPayload? get currentQrPayload => _currentQrPayload;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadDonationDetail({
    required String? token,
    required dynamic donationId,
  }) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDonationDetail = await _listingFlowRepository.getListingFlowDetail(
        token: token,
        id: donationId,
      );
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load listing details.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadListingUpdate({
    required String? token,
    required dynamic donationId,
  }) async {
    if (token == null || token.isEmpty) return;

    try {
      _currentListingUpdate = await _listingFlowRepository.getListingUpdate(
        token: token,
        id: donationId,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> adjustPrice({
    required String? token,
    required dynamic donationId,
    required double flashSalePrice,
  }) async {
    if (token == null || token.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _listingFlowRepository.adjustPrice(
        token: token,
        id: donationId,
        flashSalePrice: flashSalePrice,
      );
      return true;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to adjust flash sale price.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startClaimHold({
    required String? token,
    required dynamic donationId,
  }) async {
    if (token == null || token.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hold = await _listingFlowRepository.createClaimHold(
        token: token,
        donationId: donationId,
      );
      _activeHolds.insert(0, hold);
      return true;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to hold claim. It may have expired or been taken.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PickupQRPayload?> loadPickupQr({
    required String? token,
    dynamic claimId,
    dynamic ticketId,
  }) async {
    if (token == null || token.isEmpty) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (claimId != null) {
        _currentQrPayload = await _listingFlowRepository.getPickupQrByClaim(
          token: token,
          claimId: claimId,
        );
      } else if (ticketId != null) {
        _currentQrPayload = await _listingFlowRepository.getPickupQrByTicket(
          token: token,
          ticketId: ticketId,
        );
      }
      return _currentQrPayload;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load QR pickup ticket.');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPickupCode({
    required String? token,
    String? qrCode,
    String? manualCode,
  }) async {
    if (token == null || token.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _listingFlowRepository.verifyPickup(
        token: token,
        qrCode: qrCode,
        manualCode: manualCode,
      );
      return true;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Invalid or expired pickup verification code.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
