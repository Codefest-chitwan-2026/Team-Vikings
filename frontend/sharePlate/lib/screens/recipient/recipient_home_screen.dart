import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shareplate/screens/recipient/recipient_claimed_donations_screen.dart';
import 'package:shareplate/screens/recipient/recipient_notifications_screen.dart';
import 'package:shareplate/screens/recipient/recipient_profile_screen.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../models/recipient_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/recipient/recipient_bottom_navigation.dart';
import '../../widgets/recipient/recipient_listing_card.dart';
import '../../widgets/recipient/recipient_search_and_filters.dart';
import '../../widgets/shared/empty_state_widget.dart';
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

  List<RecipientListing> _getListings(DonationProvider provider) {
    final serverItems = provider.activeDonations;
    final freeItems = serverItems
        .where((item) => item.listingType == ListingType.donateFree)
        .map((item) => RecipientListing.fromDonationItem(item))
        .toList();

    return RecipientListingModel.filter(
      freeItems,
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
    final donationProvider = context.watch<DonationProvider>();
    final listings = _getListings(donationProvider);
    final authProvider = context.watch<AuthProvider>();
    final displayName = authProvider.currentUser?.displayName ?? 'Recipient';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryEmerald,
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
                          'Free Food Rescues',
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
                hintText: 'Search free food or donors nearby',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Available Right Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${listings.length} free',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ),
                    ],
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
                                  icon: Icons.volunteer_activism_outlined,
                                  title: 'No Priority Food Listings Right Now',
                                  description:
                                      'Nearby food businesses haven\'t posted free surplus meals at this moment. You will be notified as soon as a donor posts food.',
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