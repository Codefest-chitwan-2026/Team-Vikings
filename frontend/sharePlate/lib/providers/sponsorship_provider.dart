import 'package:flutter/material.dart';
import '../core/errors/error_sanitizer.dart';
import '../models/surplus_sponsor_model.dart';
import '../repositories/sponsorship_repository.dart';

class SponsorshipProvider extends ChangeNotifier {
  final ISponsorshipRepository _sponsorshipRepository;

  SponsorshipProvider({ISponsorshipRepository? sponsorshipRepository})
      : _sponsorshipRepository = sponsorshipRepository ?? SponsorshipRepository();

  List<SurplusSponsorItem> _items = [];
  final List<dynamic> _mySponsorships = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SurplusSponsorItem> get items => List.unmodifiable(_items);
  List<dynamic> get mySponsorships => List.unmodifiable(_mySponsorships);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchSponsorshipItems({String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _sponsorshipRepository.getSponsorshipItems(token: token);
      _items = list;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load sponsorship packages.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMySponsorships({required String? token}) async {
    if (token == null || token.isEmpty) return;
    try {
      final list = await _sponsorshipRepository.getSponsorships(token: token);
      _mySponsorships.clear();
      _mySponsorships.addAll(list);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createSponsorship({
    required String? token,
    required dynamic surplusItemId,
    required String foodTitle,
    required String donorName,
    required int mealsCount,
    required double amount,
    required double originalValue,
    String? dedication,
  }) async {
    if (token == null || token.isEmpty) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _sponsorshipRepository.createSponsorship(
        token: token,
        body: {
          'surplus_item_id': surplusItemId,
          'food_title': foodTitle,
          'donor_name': donorName,
          'meals_count': mealsCount,
          'amount': amount,
          'original_value': originalValue,
          'savings': originalValue - amount,
          'dedication': dedication ?? '',
        },
      );

      final idx = _items.indexWhere((i) => i.id == surplusItemId.toString());
      if (idx != -1) {
        final cur = _items[idx];
        final remaining = (cur.remainingMeals - mealsCount).clamp(0, cur.totalMeals);
        _items[idx] = SurplusSponsorItem(
          id: cur.id,
          donorName: cur.donorName,
          donorType: cur.donorType,
          donorAddress: cur.donorAddress,
          donorPhone: cur.donorPhone,
          distanceKm: cur.distanceKm,
          foodTitle: cur.foodTitle,
          category: cur.category,
          totalMeals: cur.totalMeals,
          remainingMeals: remaining,
          quantityUnit: cur.quantityUnit,
          servesApprox: cur.servesApprox,
          sponsorPricePerMeal: cur.sponsorPricePerMeal,
          originalPricePerMeal: cur.originalPricePerMeal,
          minutesLeft: cur.minutesLeft,
          cookedAgo: cur.cookedAgo,
          destinationNgo: cur.destinationNgo,
          destinationNgoCategory: cur.destinationNgoCategory,
          destinationAddress: cur.destinationAddress,
          description: cur.description,
          itemsIncluded: cur.itemsIncluded,
          packagingInfo: cur.packagingInfo,
          hygieneRating: cur.hygieneRating,
          bannerGradient: cur.bannerGradient,
          imageAsset: cur.imageAsset,
          isActive: remaining > 0,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Failed to process charity sponsorship.');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
