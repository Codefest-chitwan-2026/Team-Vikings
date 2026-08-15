import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';
import '../../widgets/recipient/recipient_listing_card.dart';
import '../../widgets/recipient/recipient_search_and_filters.dart';
import 'listing_detail_screen.dart';

class BrowseNearbyTab extends StatefulWidget {
  const BrowseNearbyTab({super.key});

  @override
  State<BrowseNearbyTab> createState() => _BrowseNearbyTabState();
}

class _BrowseNearbyTabState extends State<BrowseNearbyTab> {
  RecipientListingFilter _filter = RecipientListingFilter.doneCompleted;
  String _query = '';

  List<RecipientListing> get _filteredListings {
    return RecipientListingModel.filter(
      RecipientListingModel.listings,
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
    final listings = _filteredListings;

    return SafeArea(
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
              totalCount: RecipientListingModel.listings.length,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: listings.isEmpty
                ? const Center(
                    child: Text(
                      'No listings match your filters.',
                      style: TextStyle(color: AppColors.textSecondary),
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
    );
  }
}
