import 'package:flutter/material.dart';
import '../models/contribution_model.dart';
import '../models/donation_model.dart';
import '../models/nearby_ngo_model.dart';

class DonationProvider extends ChangeNotifier {
  final List<DonationItem> _activeDonations = List.from(DonationModel.activeDonations);
  final List<DonationItem> _pastDonations = List.from(DonationModel.pastDonations);
  final List<ContributionItem> _contributions = List.from(ContributionItem.mockContributions);
  final List<NearbyNgo> _nearbyNgos = List.from(NearbyNgo.mockNgos);

  List<DonationItem> get activeDonations => List.unmodifiable(_activeDonations);
  List<DonationItem> get pastDonations => List.unmodifiable(_pastDonations);
  List<ContributionItem> get contributions => List.unmodifiable(_contributions);
  List<NearbyNgo> get nearbyNgos => List.unmodifiable(_nearbyNgos);

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
