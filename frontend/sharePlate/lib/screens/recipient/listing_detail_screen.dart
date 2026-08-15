import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../models/recipient_listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import 'claim_success_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final RecipientListing listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isClaiming = false;

  // Countdown timer
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _initialRemaining();
    if (_remaining.isNegative) _remaining = Duration.zero;

    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _initialRemaining() {
    final item = widget.listing.donationItem;
    if (item?.priorityExpiresAt != null) {
      return item!.priorityExpiresAt!.difference(DateTime.now());
    }
    if (item?.prioritySecondsRemaining != null &&
        item!.prioritySecondsRemaining > 0) {
      return Duration(seconds: item.prioritySecondsRemaining);
    }
    // Fall back: use minutesLeft from listing
    return Duration(minutes: widget.listing.minutesLeft);
  }

  /// Total priority window duration (for progress bar).
  Duration _totalDuration() {
    // Default NGO priority window is 45 min
    return const Duration(minutes: 45);
  }

  double _progressValue() {
    final total = _totalDuration().inSeconds;
    if (total <= 0) return 0;
    final elapsed = total - _remaining.inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── Claim ──────────────────────────────────────────────────────────────
  Future<void> _claimListing() async {
    setState(() => _isClaiming = true);

    final auth = context.read<AuthProvider>();
    final donationProvider = context.read<DonationProvider>();

    final success = await donationProvider.claimDonationOnApi(
      token: auth.currentUser?.token,
      donationId: widget.listing.id,
      pickupMethod: 'SELF',
    );

    if (!mounted) return;
    setState(() => _isClaiming = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClaimSuccessScreen(listing: widget.listing),
        ),
      );
    } else {
      final msg = donationProvider.errorMessage ??
          'Unable to claim this listing at this moment.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _messageDonor() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Opening chat with ${widget.listing.donorName}…'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryEmerald,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  DonationItem? get _item => widget.listing.donationItem;

  String get _categoryLabel {
    switch (widget.listing.foodCategory) {
      case FoodCategory.veg:
        return 'Cooked food · Veg';
      case FoodCategory.nonVeg:
        return 'Cooked food · Non-Veg';
      case FoodCategory.mixed:
        return 'Cooked food · Mixed';
    }
  }

  String get _bestBeforeLabel {
    final bb = _item?.bestBefore;
    if (bb == null) return 'Tonight';
    final h = bb.hour;
    final m = bb.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  String get _preparedLabel {
    final bb = _item?.bestBefore;
    if (bb == null) return 'Today';
    // Estimate: prepared ~3 h before best-before
    final prep = bb.subtract(const Duration(hours: 3));
    final h = prep.hour;
    final m = prep.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return 'Today, $hour12:$m $period';
  }

  String get _pickupWindowLabel {
    final item = _item;
    if (item == null) return 'Today, check with donor';

    // Try to build from rawJson pickup window fields
    final raw = item.rawJson;
    if (raw != null) {
      final detail = raw['listing_detail'] as Map<String, dynamic>?;
      if (detail != null &&
          detail['pickup_window_start'] != null &&
          detail['pickup_window_end'] != null) {
        try {
          final start =
              DateTime.parse(detail['pickup_window_start'].toString());
          final end =
              DateTime.parse(detail['pickup_window_end'].toString());
          return 'Today, ${_fmt12(start)} – ${_fmt12(end)}';
        } catch (_) {}
      }
    }

    // Fall back: use bestBefore – pickupWindow duration
    final bb = item.bestBefore;
    if (bb != null) {
      final winMins =
          int.tryParse(item.pickupWindow.replaceAll(RegExp(r'\D'), '')) ?? 45;
      final winStart = bb.subtract(Duration(minutes: winMins));
      return 'Today, ${_fmt12(winStart)} – ${_fmt12(bb)}';
    }
    return 'Today, check with donor';
  }

  String _fmt12(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String get _estWeightLabel {
    final qty = widget.listing.quantity;
    // Rough estimate: each plate ~0.5 kg
    final kg = (qty * 0.5).round();
    return '$kg kg';
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final topPadding = MediaQuery.paddingOf(context).top;
    final isExpired = _remaining.inSeconds <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Column(
        children: [
          // ── Scrollable body ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Green Hero Header ────────────────────────────
                  _HeroHeader(
                    listing: listing,
                    topPadding: topPadding,
                  ),

                  // ── Below-header content ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── Priority countdown card ──────────────
                        if (!isExpired)
                          _PriorityCard(
                            countdown: _formatCountdown(_remaining),
                            progress: _progressValue(),
                          )
                        else
                          _ExpiredBanner(),
                        const SizedBox(height: 20),

                        // ── Food name + donor ────────────────────
                        Text(
                          '${listing.title} (${listing.foodTypeLabel.toLowerCase()})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 14,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${listing.donorName} · ${listing.pickupAddress.split(',').take(2).join(',')} · ${listing.distanceLabel} away',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Stats row ────────────────────────────
                        _StatsRow(
                          servings: listing.quantity,
                          estWeight: _estWeightLabel,
                          bestBefore: _bestBeforeLabel,
                        ),
                        const SizedBox(height: 24),

                        // ── Description (if any) ─────────────────
                        if (listing.description.trim().isNotEmpty) ...[
                          const Text(
                            'About this batch',
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
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Pickup window ────────────────────────
                        const Text(
                          'Pickup window',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PickupWindowCard(
                          timeLabel: _pickupWindowLabel,
                          instructions: listing.pickupInstructions,
                        ),
                        const SizedBox(height: 24),

                        // ── Food details ─────────────────────────
                        const Text(
                          'Food details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _FoodDetailsCard(
                          categoryLabel: _categoryLabel,
                          preparedLabel: _preparedLabel,
                        ),

                        // Space for fixed bottom bar
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed bottom action bar ────────────────────────────────
          _BottomBar(
            isClaiming: _isClaiming,
            isExpired: isExpired,
            onMessage: _messageDonor,
            onClaim: _claimListing,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.listing,
    required this.topPadding,
  });

  final RecipientListing listing;
  final double topPadding;

  String _heroSubtitle(RecipientListing l) {
    final qty = l.quantity;
    final unit = l.quantityUnit;
    final item = l.donationItem;
    if (item?.bestBefore != null) {
      final bb = item!.bestBefore!;
      final h = bb.hour % 12 == 0 ? 12 : bb.hour % 12;
      final m = bb.minute.toString().padLeft(2, '0');
      final p = bb.hour >= 12 ? 'PM' : 'AM';
      return '$qty $unit · fresh at $h:$m $p';
    }
    return '$qty $unit · available now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1EAA55), Color(0xFF0D7A3E)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button row + badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // NGO PRIORITY badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'NGO PRIORITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Food emoji
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                listing.foodCategory == FoodCategory.veg
                    ? '🥗'
                    : listing.foodCategory == FoodCategory.nonVeg
                        ? '🍗'
                        : '🥐',
                style: const TextStyle(fontSize: 34),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              listing.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle: qty · fresh at time
            Text(
              _heroSubtitle(listing),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Priority Countdown Card
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.countdown,
    required this.progress,
  });

  final String countdown;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9DD8B3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded,
                  size: 15, color: AppColors.primaryEmerald),
              const SizedBox(width: 6),
              const Text(
                'PRIORITY ACCESS REMAINING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryEmerald,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Countdown
          Text(
            countdown,
            style: const TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryEmerald,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFC8EDD8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryEmerald),
            ),
          ),
          const SizedBox(height: 10),

          // Sub-label
          const Text(
            'Unclaimed listings convert to a flash sale automatically.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFE65100)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'NGO priority window has ended. This listing is now available as a flash sale.',
              style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFBF360C),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.servings,
    required this.estWeight,
    required this.bestBefore,
  });

  final int servings;
  final String estWeight;
  final String bestBefore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.people_outline_rounded,
                value: '$servings',
                label: 'Servings',
              ),
            ),
            _vDivider(),
            Expanded(
              child: _StatCell(
                icon: Icons.scale_outlined,
                value: estWeight,
                label: 'Est. weight',
              ),
            ),
            _vDivider(),
            Expanded(
              child: _StatCell(
                icon: Icons.schedule_rounded,
                value: bestBefore,
                label: 'Best before',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        color: AppColors.border,
        margin: const EdgeInsets.symmetric(vertical: 12),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEmerald),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pickup Window Card
// ─────────────────────────────────────────────────────────────────────────────

class _PickupWindowCard extends StatelessWidget {
  const _PickupWindowCard({
    required this.timeLabel,
    required this.instructions,
  });

  final String timeLabel;
  final String instructions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time_rounded,
                color: AppColors.primaryEmerald, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instructions,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// Food Details Card
// ─────────────────────────────────────────────────────────────────────────────

class _FoodDetailsCard extends StatelessWidget {
  const _FoodDetailsCard({
    required this.categoryLabel,
    required this.preparedLabel,
  });

  final String categoryLabel;
  final String preparedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _detailRow(
            icon: Icons.restaurant_outlined,
            label: 'Category',
            value: categoryLabel,
            isFirst: true,
          ),
          _divider(),
          _detailRow(
            icon: Icons.inventory_2_outlined,
            label: 'Packaging',
            value: 'Foil trays, sealed',
          ),
          _divider(),
          _detailRow(
            icon: Icons.timer_outlined,
            label: 'Prepared',
            value: preparedLabel,
          ),
          _divider(),
          _detailRow(
            icon: Icons.verified_outlined,
            label: 'Hygiene assurance',
            value: 'Confirmed by donor',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, color: AppColors.border);
}

// ─────────────────────────────────────────────────────────────────────────────
// Fixed Bottom Action Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isClaiming,
    required this.isExpired,
    required this.onMessage,
    required this.onClaim,
  });

  final bool isClaiming;
  final bool isExpired;
  final VoidCallback onMessage;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Message button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onMessage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryEmerald,
                      side: const BorderSide(
                          color: AppColors.primaryEmerald, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 18),
                    label: const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Claim button
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (isClaiming || isExpired) ? null : onClaim,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      disabledBackgroundColor:
                          AppColors.primaryEmerald.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isClaiming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isExpired
                                ? 'Priority Expired'
                                : 'Claim this donation',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
