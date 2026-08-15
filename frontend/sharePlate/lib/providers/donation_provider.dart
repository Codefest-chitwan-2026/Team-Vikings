import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/errors/error_sanitizer.dart';
import '../models/contribution_model.dart';
import '../models/donation_model.dart';
import '../models/nearby_ngo_model.dart';
import '../repositories/contribution_repository.dart';
import '../repositories/donation_repository.dart';
import '../repositories/profile_repository.dart';

class DonationProvider extends ChangeNotifier {
  final IDonationRepository _donationRepository;
  final IProfileRepository _profileRepository;
  final IContributionRepository _contributionRepository;

  DonationProvider({
    IDonationRepository? donationRepository,
    IProfileRepository? profileRepository,
    IContributionRepository? contributionRepository,
  })  : _donationRepository = donationRepository ?? DonationRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _contributionRepository = contributionRepository ?? ContributionRepository();

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle) {
      binding.addPostFrameCallback((_) {
        if (!_isDisposed && hasListeners) {
          super.notifyListeners();
        }
      });
    } else {
      super.notifyListeners();
    }
  }

  final List<DonationItem> _activeDonations = [];
  final List<DonationItem> _pastDonations = [];
  final List<DonationItem> _ngoPriorityDonations = [];
  final List<DonationItem> _flashSaleDonations = [];
  final List<ContributionItem> _contributions = [];
  final List<NearbyNgo> _nearbyNgos = [];
  final List<dynamic> _claims = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<DonationItem> get activeDonations => List.unmodifiable(_activeDonations);
  List<DonationItem> get pastDonations => List.unmodifiable(_pastDonations);
  List<DonationItem> get ngoPriorityDonations => List.unmodifiable(_ngoPriorityDonations);
  List<DonationItem> get flashSaleDonations => List.unmodifiable(_flashSaleDonations);
  List<ContributionItem> get contributions => List.unmodifiable(_contributions);
  List<NearbyNgo> get nearbyNgos => List.unmodifiable(_nearbyNgos);
  List<dynamic> get claims => List.unmodifiable(_claims);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch donations from backend API
  Future<void> fetchDonations({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _donationRepository.getDonations(token: token);
      _activeDonations.clear();
      _pastDonations.clear();

      for (final donation in list) {
        if (donation.isActive) {
          _activeDonations.add(donation);
        } else {
          _pastDonations.add(donation);
        }
      }
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load donations at this moment.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch NGO priority listings for Recipient app
  Future<void>  fetchNgoPriorityListings({required String? token}) async {
    if (token == null || token.isEmpty) {
      debugPrint('[DonationProvider] fetchNgoPriorityListings: skipped, no token');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[DonationProvider] fetchNgoPriorityListings: requesting with token=${token.substring(0, token.length < 12 ? token.length : 12)}...');
      final list = await _donationRepository.getNgoPriorityDonations(token: token);
      debugPrint('[DonationProvider] fetchNgoPriorityListings: got ${list.length} item(s) back');
      _ngoPriorityDonations.clear();
      _ngoPriorityDonations.addAll(list);
    } catch (e, st) {
      debugPrint('[DonationProvider] fetchNgoPriorityListings: FAILED — $e');
      debugPrint('$st');
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load priority food listings.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch Flash Sale deals for Consumers
  Future<void> fetchFlashSales({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _donationRepository.getFlashSales(token: token);
      _flashSaleDonations.clear();
      _flashSaleDonations.addAll(list);
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load discount deals.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch Nearby NGOs
  Future<void> fetchNearbyNgos({double? lat, double? lng, double? radiusKm}) async {
    try {
      final list = await _profileRepository.getNearbyNgos(
        latitude: lat,
        longitude: lng,
        radiusKm: radiusKm,
      );
      _nearbyNgos.clear();
      _nearbyNgos.addAll(list);
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch Contributions
  Future<void> fetchContributions({required String? token}) async {
    if (token == null || token.isEmpty) return;

    try {
      final list = await _contributionRepository.getContributions(token: token);
      _contributions.clear();
      _contributions.addAll(list);
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch Claims
  Future<void> fetchClaims({required String? token}) async {
    if (token == null || token.isEmpty) return;

    try {
      final list = await _donationRepository.getClaims(token: token);
      _claims.clear();
      _claims.addAll(list);
      notifyListeners();
    } catch (_) {}
  }

  /// Create donation listing on backend
  Future<bool> createDonationOnApi({
    required String? token,
    required String title,
    required String description,
    required String foodType,
    required double quantity,
    required String quantityUnit,
    required int peopleServed,
    required DateTime bestBefore,
    required String pickupAddress,
    double? latitude,
    double? longitude,
    String? listingType,
    double? price,
    double? flashSalePrice,
    String? imagePath,
  }) async {
    final fields = <String, String>{
      'title': title,
      'description': description,
      'food_type': foodType.toUpperCase(),
      'quantity': quantity.toString(),
      'quantity_unit': quantityUnit,
      'people_served': peopleServed.toString(),
      'best_before': bestBefore.toIso8601String(),
      'pickup_address': pickupAddress,
    };
    if (latitude != null) fields['latitude'] = latitude.toString();
    if (longitude != null) fields['longitude'] = longitude.toString();
    if (listingType != null) fields['listing_type'] = listingType.toUpperCase();
    if (price != null) fields['price'] = price.toString();
    if (flashSalePrice != null) fields['flash_sale_price'] = flashSalePrice.toString();

    final localItem = DonationItem(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      postedAgo: 'Just now',
      title: '$title · ${quantity.toInt()} $quantityUnit',
      category: foodType.toUpperCase().contains('NON')
          ? FoodCategory.nonVeg
          : (foodType.toUpperCase().contains('MIX') ? FoodCategory.mixed : FoodCategory.veg),
      quantity: quantity.toInt(),
      quantityUnit: quantityUnit,
      servesApprox: '$peopleServed people',
      status: DonationStatus.awaitingClaim,
      isActive: true,
      pickupAddress: pickupAddress,
      pickupLatitude: latitude,
      pickupLongitude: longitude,
      listingType: listingType?.toUpperCase() == 'FLASH_SALE'
          ? ListingType.discountedSale
          : ListingType.donateFree,
      originalPrice: price,
      discountedPrice: flashSalePrice,
      imagePath: imagePath,
      description: description,
      receiptNumber: 'SP-DON-2026-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );

    _activeDonations.insert(0, localItem);
    notifyListeners();

    if (token != null && token.isNotEmpty) {
      try {
        final serverItem = await _donationRepository.createDonation(
          token: token,
          fields: fields,
          imagePath: imagePath,
        );
        final idx = _activeDonations.indexWhere((d) => d.id == localItem.id);
        if (idx != -1) {
          _activeDonations[idx] = serverItem;
          notifyListeners();
        }
        return true;
      } catch (e) {
        // Roll back the optimistic item — it never made it to the backend.
        _activeDonations.removeWhere((d) => d.id == localItem.id);
        _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Failed to publish food listing. Please try again.');
        notifyListeners();
        return false;
      }
    }
    // No token means we never even attempted the API call — this should not
    // silently report success either.
    _activeDonations.removeWhere((d) => d.id == localItem.id);
    notifyListeners();
    return false;
  }

  /// Claim a donation listing (NGO role)
  Future<bool> claimDonationOnApi({
    required String? token,
    required String donationId,
    String pickupMethod = 'SELF',
    DateTime? scheduledPickupStart,
    DateTime? scheduledPickupEnd,
    String? volunteerName,
    String? volunteerPhone,
    String? donorNote,
    int? peopleServedConfirmed,
  }) async {
    final idx = _activeDonations.indexWhere((d) => d.id == donationId);
    if (idx != -1) {
      _activeDonations[idx] = _activeDonations[idx].copyWith(
        status: DonationStatus.ngoEnRoute,
      );
      notifyListeners();
    }

    if (token != null && token.isNotEmpty) {
      try {
        await _donationRepository.claimDonation(
          token: token,
          id: donationId,
          pickupMethod: pickupMethod,
          scheduledPickupStart: scheduledPickupStart,
          scheduledPickupEnd: scheduledPickupEnd,
          volunteerName: volunteerName,
          volunteerPhone: volunteerPhone,
          donorNote: donorNote,
          peopleServedConfirmed: peopleServedConfirmed,
        );
        return true;
      } catch (e) {
        _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to claim donation. It may have expired or been taken.');
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  /// Reserve a flash sale listing (Customer role)
  Future<Map<String, dynamic>?> reserveFlashSaleOnApi({
    required String? token,
    required String donationId,
  }) async {
    if (token != null && token.isNotEmpty) {
      try {
        return await _donationRepository.reserveDonation(token: token, id: donationId);
      } catch (e) {
        _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to reserve deal. It may already be claimed.');
        notifyListeners();
        return null;
      }
    }
    return null;
  }

  /// Cancel a donation listing
  Future<bool> cancelDonationOnApi({
    required String? token,
    required String donationId,
  }) async {
    if (token == null || token.isEmpty) {
      // No token means we can't confirm this with the backend — don't
      // pretend it succeeded.
      return false;
    }

    try {
      await _donationRepository.cancelDonation(
        token: token,
        id: donationId,
      );
      // Only move it to "past" locally once the backend has confirmed.
      cancelDonation(donationId);
      return true;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to cancel donation.');
      notifyListeners();
      return false;
    }
  }

  /// Verify pickup via QR or manual code
  Future<bool> verifyPickupOnApi({
    required String? token,
    required String qrCode,
  }) async {
    if (token != null && token.isNotEmpty) {
      try {
        await _donationRepository.verifyPickup(token: token, qrCode: qrCode);
        return true;
      } catch (e) {
        _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Invalid pickup verification code.');
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  void addDonation(DonationItem donation) {
    _activeDonations.insert(0, donation);
    notifyListeners();
  }

  void updateDonation(DonationItem updated) {
    final activeIndex = _activeDonations.indexWhere((d) => d.id == updated.id);
    if (activeIndex != -1) {
      _activeDonations[activeIndex] = updated;
      notifyListeners();
      return;
    }

    final pastIndex = _pastDonations.indexWhere((d) => d.id == updated.id);
    if (pastIndex != -1) {
      _pastDonations[pastIndex] = updated;
      notifyListeners();
    }
  }

  DonationItem repeatDonation(DonationItem original) {
    final newDonation = original.copyWith(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      postedAgo: 'Just now',
      status: DonationStatus.awaitingClaim,
      isActive: true,
      recipient: null,
      recipientPhone: null,
      recipientAddress: null,
      receiptNumber: 'SP-DON-${DateTime.now().year}-${1000 + _activeDonations.length + 1}',
    );

    _activeDonations.insert(0, newDonation);
    notifyListeners();
    return newDonation;
  }

  void cancelDonation(String id) {
    final index = _activeDonations.indexWhere((d) => d.id == id);
    if (index != -1) {
      final removed = _activeDonations.removeAt(index);
      _pastDonations.insert(
        0,
        removed.copyWith(
          isActive: false,
          status: DonationStatus.completed,
          postedAgo: 'Cancelled',
        ),
      );
      notifyListeners();
    }
  }

  DonationItem? findDonationById(String id) {
    for (final d in _activeDonations) {
      if (d.id == id) return d;
    }
    for (final d in _pastDonations) {
      if (d.id == id) return d;
    }
    return null;
  }
}