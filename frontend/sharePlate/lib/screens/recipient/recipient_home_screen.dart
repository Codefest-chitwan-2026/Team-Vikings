import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shareplate/screens/recipient/recipient_claimed_donations_screen.dart';
import 'package:shareplate/screens/recipient/recipient_notifications_screen.dart';
import 'package:shareplate/screens/recipient/recipient_profile_screen.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/recipient/recipient_bottom_navigation.dart';
import '../../widgets/recipient/recipient_listing_card.dart';
import '../../widgets/recipient/recipient_search_and_filters.dart';
import 'browse_nearby_tab.dart';
import 'listing_detail_screen.dart';

class RecipientHomeScreen extends StatefulWidget {
  const RecipientHomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<RecipientHomeScreen> createState() => _RecipientHomeScreenState();
}

class _RecipientHomeScreenState extends State<RecipientHomeScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecipientNotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _RecipientHomeTab(
            onNotificationsTap: _openNotifications,
            onSeeMoreTap: () => _onTabSelected(1),
          ),
          const BrowseNearbyTab(),
          const RecipientClaimedDonationsScreen(),
          const RecipientProfileScreen(),
        ],
      ),
      bottomNavigationBar: RecipientBottomNavigation(
        currentIndex: _selectedTab,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _RecipientHomeTab extends StatefulWidget {
  const _RecipientHomeTab({
    required this.onNotificationsTap,
    required this.onSeeMoreTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onSeeMoreTap;

  @override
  State<_RecipientHomeTab> createState() => _RecipientHomeTabState();
}

class _RecipientHomeTabState extends State<_RecipientHomeTab> {
  bool _showFreeListings = true;
  String _query = '';

  List<RecipientListing> get _filteredListings {
    final typeFiltered = RecipientListingModel.listings.where((listing) {
      return _showFreeListings ? listing.isFree : !listing.isFree;
    });

    return RecipientListingModel.filter(
      typeFiltered.toList(),
      filter: RecipientListingFilter.remaining,
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
    final authProvider = context.watch<AuthProvider>();
    final displayName = authProvider.currentUser?.displayName ?? 'Recipient';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $displayName',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'You are a Recipient',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.surface,
                  shape: const CircleBorder(
                    side: BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onNotificationsTap,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RecipientSearchBar(
              hintText: 'Search food or donors nearby',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RecipientListingTypeToggle(
              showFree: _showFreeListings,
              onChanged: (showFree) => setState(() => _showFreeListings = showFree),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Right Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: widget.onSeeMoreTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1677D2),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('See More', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: listings.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _showFreeListings
                            ? Icons.volunteer_activism_outlined
                            : Icons.local_offer_outlined,
                        size: 30,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _showFreeListings
                          ? 'No free listings right now'
                          : 'No discounted deals right now',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showFreeListings
                          ? 'New free-to-claim food will show up here as soon as a donor posts it nearby.'
                          : 'New discounted deals will show up here as soon as a donor posts one nearby.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
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