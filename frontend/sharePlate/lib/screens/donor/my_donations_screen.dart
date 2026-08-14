import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/donation_model.dart';
import '../../../screens/donor/add_donation_screen.dart';
import '../../../screens/donor/track_donation_screen.dart';
import '../../widgets/donor/donation/donation_card.dart';
import '../../widgets/donor/donation/donation_tab_selector.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  int _selectedTab = 0;

  List<DonationItem> get _visibleDonations => _selectedTab == 0
      ? DonationModel.activeDonations
      : DonationModel.pastDonations;

  void _handleAction(DonationItem donation, DonationCardAction action) {
    switch (action) {
      case DonationCardAction.track:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TrackDonationScreen(donation: donation),
          ),
        );
      case DonationCardAction.edit:
      case DonationCardAction.boost:
      case DonationCardAction.cancel:
      case DonationCardAction.receipt:
      case DonationCardAction.repeat:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.name} coming soon.')),
        );
    }
  }

  void _openAddDonation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddDonationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                activeCount: DonationModel.activeDonations.length,
                pastCount: 24,
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: _visibleDonations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final donation = _visibleDonations[index];
                  return DonationCard(
                    donation: donation,
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
