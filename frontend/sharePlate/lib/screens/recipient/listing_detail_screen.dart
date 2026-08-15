import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/recipient_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/login_screen/primary_button.dart';
import 'claim_success_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final RecipientListing listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isClaiming = false;

  Future<void> _claimListing() async {
    setState(() => _isClaiming = true);

    final authProvider = context.read<AuthProvider>();
    final donationProvider = context.read<DonationProvider>();

    await donationProvider.claimDonationOnApi(
      token: authProvider.currentUser?.token,
      donationId: widget.listing.id,
      pickupMethod: 'SELF',
    );

    if (!mounted) return;
    setState(() => _isClaiming = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ClaimSuccessScreen(listing: widget.listing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final badgeColor =
        listing.isFree ? AppColors.primaryEmerald : AppColors.secondary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeaderSection(listing: listing, badgeColor: badgeColor),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${listing.donorName} · ${listing.area} · ${listing.distanceLabel} away',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _QuickStatsRow(listing: listing),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (!listing.isFree) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Pricing',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (listing.originalPrice != null)
                              Text(
                                'Rs ${listing.originalPrice!.toInt()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (listing.originalPrice != null)
                              const SizedBox(width: 10),
                            Text(
                              listing.priceLabel ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Pickup details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _PickupCard(listing: listing),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                text: listing.isFree
                    ? 'Claim this listing →'
                    : 'Buy at ${listing.priceLabel ?? 'discount'} →',
                isLoading: _isClaiming,
                onPressed: _claimListing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.listing,
    required this.badgeColor,
  });

  final RecipientListing listing;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Container(
          height: 220 + topPadding,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: listing.headerGradient,
            ),
          ),
        ),
        Positioned(
          top: topPadding + 8,
          left: 12,
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topPadding + 8,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              listing.claimBadgeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.listing});

  final RecipientListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: '${listing.quantity}',
              label: listing.quantityUnit,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _StatCell(value: listing.foodTypeLabel, label: 'Type'),
          ),
          _verticalDivider(),
          Expanded(
            child: _StatCell(
              value: '${listing.minutesLeft} min',
              label: 'Left to claim',
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PickupCard extends StatelessWidget {
  const _PickupCard({required this.listing});

  final RecipientListing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryEmerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.pickupAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  listing.pickupInstructions,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
