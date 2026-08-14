import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/donation_model.dart';
import '../../../providers/donation_provider.dart';
import '../../../screens/donor/add_donation_screen.dart';
import '../../../screens/donor/track_donation_screen.dart';
import '../../widgets/donor/donation/donation_card.dart';
import '../../widgets/donor/donation/donation_tab_selector.dart';
import 'donation_detail_screen.dart';
import 'donation_receipt_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  int _selectedTab = 0;

  void _handleAction(DonationItem donation, DonationCardAction action) {
    switch (action) {
      case DonationCardAction.track:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TrackDonationScreen(donation: donation),
          ),
        );
        break;
      case DonationCardAction.edit:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddDonationScreen(donationToEdit: donation),
          ),
        );
        break;
      case DonationCardAction.receipt:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DonationReceiptScreen(donation: donation),
          ),
        );
        break;
      case DonationCardAction.repeat:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddDonationScreen(
              prefilledTitle: donation.title.split('·').first.trim(),
              prefilledQuantity: donation.quantity.toString(),
              prefilledCategory: donation.category,
              prefilledServes: donation.servesApprox,
              prefilledAddress: donation.pickupAddress,
            ),
          ),
        );
        break;
      case DonationCardAction.boost:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing boosted! Notified 15+ NGOs in your area on priority.'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case DonationCardAction.cancel:
        _confirmCancel(donation);
        break;
    }
  }

  void _confirmCancel(DonationItem donation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Donation?'),
        content: const Text(
          'Are you sure you want to cancel this food listing?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Listing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<DonationProvider>().cancelDonation(donation.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation listing cancelled.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Cancel Listing'),
          ),
        ],
      ),
    );
  }

  void _openAddDonation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDonationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final activeDonations = donationProvider.activeDonations;
    final pastDonations = donationProvider.pastDonations;
    final visibleDonations = _selectedTab == 0 ? activeDonations : pastDonations;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'My Donations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: DonationTabSelector(
                activeCount: activeDonations.length,
                pastCount: pastDonations.length,
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
            Expanded(
              child: visibleDonations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            _selectedTab == 0 ? 'No active donations right now' : 'No past donation history',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the + button below to post surplus meals.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: visibleDonations.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final donation = visibleDonations[index];
                        return DonationCard(
                          donation: donation,
                          onCardTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DonationDetailScreen(donation: donation),
                              ),
                            );
                          },
                          onActionTap: (action) => _handleAction(donation, action),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDonation,
        backgroundColor: AppColors.primaryEmerald,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
