import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';
import 'sponsor_batch_screen.dart';

class ConsumerSponsorCharityScreen extends StatefulWidget {
  const ConsumerSponsorCharityScreen({super.key});

  @override
  State<ConsumerSponsorCharityScreen> createState() =>
      _ConsumerSponsorCharityScreenState();
}

class _ConsumerSponsorCharityScreenState
    extends State<ConsumerSponsorCharityScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDonations());
  }

  Future<void> _fetchDonations() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    await context.read<DonationProvider>().fetchDonations(token: token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns only FREE / donation-type listings (no price = going to NGO).
  List<DonationItem> _getFreeDonations(DonationProvider provider) {
    final free = provider.activeDonations.where((d) {
      // A listing is "free" when it has no discounted price and its listing
      // type is DONATION (not a flash sale). We also keep items whose
      // listing type is explicitly donateFree.
      final isFreeType = d.listingType == ListingType.donateFree;
      final hasNoPrice =
          d.discountedPrice == null || d.discountedPrice! <= 0;
      return isFreeType && hasNoPrice;
    }).toList();

    if (_searchQuery.trim().isEmpty) return free;

    final q = _searchQuery.trim().toLowerCase();
    return free.where((d) {
      return d.title.toLowerCase().contains(q) ||
          (d.donorBusinessName ?? '').toLowerCase().contains(q) ||
          d.pickupAddress.toLowerCase().contains(q) ||
          d.category.label.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DonationProvider>();
    final donations = _getFreeDonations(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Charity Sponsorship 💚',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          donations.isNotEmpty
                              ? '${donations.length} free batch${donations.length == 1 ? '' : 'es'} need your support'
                              : 'Help fund surplus food to reach NGOs',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppColors.primaryEmerald.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.volunteer_activism_rounded,
                            size: 16, color: AppColors.primaryEmerald),
                        const SizedBox(width: 5),
                        Text(
                          '${donations.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Info Banner ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.primaryEmerald),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'These batches are donated FREE by local businesses to NGOs. '
                        'Sponsor logistics to help food reach shelters & orphanages.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Search ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search food, donor, location…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Section heading ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Free Batches Available',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${donations.length} listed',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: provider.isLoading && donations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryEmerald))
                  : donations.isEmpty
                      ? Center(
                          child: provider.errorMessage != null
                              ? EmptyStateWidget(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Couldn\'t Load Donations',
                                  description: provider.errorMessage!,
                                  buttonText: 'Try Again',
                                  buttonIcon: Icons.refresh_rounded,
                                  onButtonPressed: _fetchDonations,
                                )
                              : EmptyStateWidget(
                                  icon: Icons.volunteer_activism_outlined,
                                  title: 'No Free Batches Right Now',
                                  description:
                                      'There are no free food donations available to sponsor at the moment. Check back soon — businesses post new batches regularly!',
                                  buttonText: 'Refresh',
                                  buttonIcon: Icons.refresh_rounded,
                                  onButtonPressed: _fetchDonations,
                                ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryEmerald,
                          onRefresh: _fetchDonations,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            itemCount: donations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final d = donations[i];
                              return _SponsorBatchTile(
                                donation: d,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SponsorBatchScreen(donation: d),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sponsor Batch Tile ──────────────────────────────────────────────────────

class _SponsorBatchTile extends StatelessWidget {
  const _SponsorBatchTile({
    required this.donation,
    required this.onTap,
  });

  final DonationItem donation;
  final VoidCallback onTap;

  static String _emoji(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return '🥗';
      case FoodCategory.nonVeg:
        return '🍗';
      case FoodCategory.mixed:
        return '🥐';
    }
  }

  static Color _categoryColor(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return const Color(0xFF2E7D32);
      case FoodCategory.nonVeg:
        return const Color(0xFF6A1B9A);
      case FoodCategory.mixed:
        return const Color(0xFFE65100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(donation.category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: emoji icon + title + FREE badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _emoji(donation.category),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            donation.donorBusinessName?.isNotEmpty == true
                                ? donation.donorBusinessName!
                                : 'Local Food Business',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: catColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // FREE badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primaryEmerald
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description (if any)
                if (donation.description != null &&
                    donation.description!.trim().isNotEmpty) ...[
                  Text(
                    donation.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Info chips: quantity + serves + pickup window
                Row(
                  children: [
                    _chip(Icons.inventory_2_outlined,
                        '${donation.quantity} ${donation.quantityUnit}'),
                    const SizedBox(width: 6),
                    _chip(Icons.people_outline, donation.servesApprox),
                    const SizedBox(width: 6),
                    _chip(Icons.schedule_outlined, donation.pickupWindow),
                  ],
                ),
                const SizedBox(height: 10),

                // Pickup address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        donation.pickupAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),

                // Bottom row: "Sponsor logistics" label + button
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FREE — going to NGO',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sponsor logistics to deliver this batch',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.volunteer_activism_rounded,
                          size: 15),
                      label: const Text(
                        'Sponsor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
