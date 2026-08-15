import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../models/recipient_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/recipient/recipient_listing_card.dart';
import '../../widgets/recipient/recipient_search_and_filters.dart';
import '../../widgets/shared/empty_state_widget.dart';
import 'listing_detail_screen.dart';

class BrowseNearbyTab extends StatefulWidget {
  const BrowseNearbyTab({super.key});

  @override
  State<BrowseNearbyTab> createState() => _BrowseNearbyTabState();
}

class _BrowseNearbyTabState extends State<BrowseNearbyTab> {
  RecipientListingFilter _filter = RecipientListingFilter.remaining;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      await context.read<DonationProvider>().fetchDonations(token: token);
    }
  }

  List<RecipientListing> _getFilteredListings(DonationProvider provider) {
    final serverItems = provider.activeDonations;
    final allListings = serverItems
        .where((item) => item.listingType == ListingType.donateFree)
        .map((item) => RecipientListing.fromDonationItem(item))
        .toList();

    return RecipientListingModel.filter(
      allListings,
      filter: _filter,
      query: _query,
    );
  }

  void _openListing(RecipientListing listing) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listing: listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final listings = _getFilteredListings(donationProvider);
    final totalCount = donationProvider.activeDonations
        .where((item) => item.listingType == ListingType.donateFree)
        .length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryEmerald,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'Browse Nearby',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: RecipientSearchBar(
                hintText: 'Search food, donor, area',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: RecipientFilterChips(
                selected: _filter,
                totalCount: totalCount,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: donationProvider.isLoading && listings.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryEmerald),
                    )
                  : listings.isEmpty
                      ? Center(
                          child: donationProvider.errorMessage != null
                              ? EmptyStateWidget(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Couldn\'t Load Listings',
                                  description: donationProvider.errorMessage!,
                                  buttonText: 'Try Again',
                                  buttonIcon: Icons.refresh_rounded,
                                  onButtonPressed: _refresh,
                                )
                              : EmptyStateWidget(
                                  icon: Icons.explore_off_outlined,
                                  title: 'No Food Listings Nearby',
                                  description:
                                      'No priority surplus food listings found nearby at the moment. As businesses post donations, they will appear here.',
                                  buttonText: 'Refresh Listings',
                                  buttonIcon: Icons.refresh_rounded,
                                  onButtonPressed: _refresh,
                                ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          itemCount: listings.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final listing = listings[index];
                            return RecipientListingCard(
                              listing: listing,
                              showAreaInSubtitle: false,
                              onTap: () => _openListing(listing),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}