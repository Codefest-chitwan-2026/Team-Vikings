import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/contribution_model.dart';
import '../models/donation_model.dart';
import '../models/nearby_ngo_model.dart';
import '../services/donations_api_service.dart';

class DonationProvider extends ChangeNotifier {
  final DonationsApiService _donationsApiService;

  DonationProvider({DonationsApiService? donationsApiService})
      : _donationsApiService = donationsApiService ?? DonationsApiService();

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

  final List<DonationItem> _activeDonations = List.from(DonationModel.activeDonations);
  final List<DonationItem> _pastDonations = List.from(DonationModel.pastDonations);
  final List<ContributionItem> _contributions = List.from(ContributionItem.mockContributions);
  final List<NearbyNgo> _nearbyNgos = List.from(NearbyNgo.mockNgos);

  bool _isLoading = false;
  String? _errorMessage;

  List<DonationItem> get activeDonations => List.unmodifiable(_activeDonations);
  List<DonationItem> get pastDonations => List.unmodifiable(_pastDonations);
  List<ContributionItem> get contributions => List.unmodifiable(_contributions);
  List<NearbyNgo> get nearbyNgos => List.unmodifiable(_nearbyNgos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch donations from backend API
  Future<void> fetchDonations({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _donationsApiService.getDonations(token: token);
      if (list.isNotEmpty) {
        _activeDonations.clear();
        _pastDonations.clear();

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final donation = DonationItem.fromJson(item);
            if (donation.isActive) {
              _activeDonations.add(donation);
            } else {
              _pastDonations.add(donation);
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

    // Optimistically add to local list
    final localItem = DonationItem(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      postedAgo: 'Just now',
      title: '$title · ${quantity.toInt()} $quantityUnit',
      category: foodType.toUpperCase() == 'NONVEG'
          ? FoodCategory.nonVeg
          : (foodType.toUpperCase() == 'MIXED' ? FoodCategory.mixed : FoodCategory.veg),
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
        final res = await _donationsApiService.createDonation(
          token: token,
          fields: fields,
          imagePath: imagePath,
        );
        if (res.containsKey('id')) {
          final serverItem = DonationItem.fromJson(res);
          final idx = _activeDonations.indexWhere((d) => d.id == localItem.id);
          if (idx != -1) {
            _activeDonations[idx] = serverItem;
            notifyListeners();
          }
        }
        return true;
      } catch (e) {
        _errorMessage = e.toString();
      }
    }
    return true;
  }

  /// Claim a donation listing (NGO role)
  Future<bool> claimDonationOnApi({
    required String? token,
    required String donationId,
    String pickupMethod = 'SELF',
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
        await _donationsApiService.claimDonation(
          token: token,
          id: donationId,
          pickupMethod: pickupMethod,
        );
        return true;
      } catch (e) {
        _errorMessage = e.toString();
      }
    }
    return true;
  }

  /// Cancel a donation listing
  Future<bool> cancelDonationOnApi({
    required String? token,
    required String donationId,
  }) async {
    cancelDonation(donationId);

    if (token != null && token.isNotEmpty) {
      try {
        await _donationsApiService.cancelDonation(
          token: token,
          id: donationId,
        );
        return true;
      } catch (e) {
        _errorMessage = e.toString();
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
