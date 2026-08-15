import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';
import 'consumer_deal_detail_screen.dart';
import 'consumer_notifications_screen.dart';

class ConsumerDealsTab extends StatefulWidget {
  const ConsumerDealsTab({super.key, this.onNavigateToSponsor});

  final VoidCallback? onNavigateToSponsor;

  @override
  State<ConsumerDealsTab> createState() => _ConsumerDealsTabState();
}

class _ConsumerDealsTabState extends State<ConsumerDealsTab> {
  String _searchQuery = '';
  FoodCategory? _selectedCategory;

  // Periodic refresh timer to keep countdowns and the list fresh.
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFlashSales();
    });

    // Rebuild every minute so best-before countdowns stay current.
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFlashSales() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      await context.read<DonationProvider>().fetchFlashSales(token: token);
    }
  }

  List<DonationItem> _getFilteredSales(List<DonationItem> flashSales) {
    // Sort newest-first by postedAgo semantics: items with rawJson created_at
    // are sorted descending; others keep their original order.
    final sorted = [...flashSales];
    sorted.sort((a, b) {
      final ta = _createdAt(a);
      final tb = _createdAt(b);
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta); // newest first
    });

    return sorted.where((item) {
      // Category filter
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      // Search filter: matches title, address, or business name
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesAddress = item.pickupAddress.toLowerCase().contains(query);
        final matchesBusiness =
            (item.donorBusinessName ?? '').toLowerCase().contains(query);
        return matchesTitle || matchesAddress || matchesBusiness;
      }
      return true;
    }).toList();
  }

  DateTime? _createdAt(DonationItem item) {
    final raw = item.rawJson?['created_at']?.toString();
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final list = _getFilteredSales(donationProvider.flashSaleDonations);
    final total = donationProvider.flashSaleDonations.length;
    final isLoading = donationProvider.isLoading;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Flash Deals ⚡',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total > 0
                          ? '$total deal${total == 1 ? '' : 's'} • up to 70% off'
                          : 'Rescue premium meals at up to 70% off',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.primaryEmerald),
                      tooltip: 'Refresh',
                      onPressed: _loadFlashSales,
                    ),
                    Material(
                      color: AppColors.surface,
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ConsumerNotificationsScreen(),
                            ),
                          );
                        },
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Search Bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search food, store, locality…',
                hintStyle: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Sponsor Charity Food Banner ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: widget.onNavigateToSponsor,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryEmerald.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: AppColors.primaryEmerald,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sponsor Food for NGOs',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Fund surplus meals for local shelters & orphanages',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sponsor',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Category Chips ───────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildCategoryChip(null, 'All Deals'),
                _buildCategoryChip(FoodCategory.veg, '🌱 Pure Veg'),
                _buildCategoryChip(FoodCategory.nonVeg, '🍗 Non-Veg'),
                _buildCategoryChip(FoodCategory.mixed, '🥖 Bakery / Mixed'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Deals List ───────────────────────────────────────────────────
          Expanded(
            child: isLoading && list.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryEmerald))
                : list.isEmpty
                    ? Center(
                        child: EmptyStateWidget(
                          icon: Icons.bolt_rounded,
                          title: 'No Flash Deals Right Now',
                          description:
                              'Nearby restaurants and bakeries have not posted discount deals yet. Check back soon for fresh surplus food discounts!',
                          buttonText: 'Refresh Deals',
                          buttonIcon: Icons.refresh_rounded,
                          onButtonPressed: _loadFlashSales,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFlashSales,
                        color: AppColors.primaryEmerald,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, idx) {
                            final item = list[idx];
                            return _FlashSaleCard(
                              item: item,
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ConsumerDealDetailScreen(
                                              deal: item),
                                    ),
                                  )
                                  .then((_) => _loadFlashSales()),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(FoodCategory? cat, String label) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.charcoal,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryEmerald,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                isSelected ? AppColors.primaryEmerald : AppColors.border,
          ),
        ),
        onSelected: (_) =>
            setState(() => _selectedCategory = cat),
      ),
    );
  }
}

// ── Flash Sale Card ────────────────────────────────────────────────────────────

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({required this.item, required this.onTap});

  final DonationItem item;
  final VoidCallback onTap;

  /// Builds a full absolute image URL from whatever the backend stored.
  /// If [imagePath] is already a full URL it is returned as-is.
  static String? _resolveImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Strip leading slash so we don't double up.
    final relative =
        imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '${ApiConstants.baseUrl}/$relative';
  }

  /// Returns the emoji icon for this food category.
  static String _categoryEmoji(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return '🥗';
      case FoodCategory.nonVeg:
        return '🍗';
      case FoodCategory.mixed:
        return '🥐';
    }
  }

  /// Returns a human-readable countdown until [dateTime].
  /// Returns null if [dateTime] is null or already in the past.
  static String? _countdown(DateTime? dateTime) {
    if (dateTime == null) return null;
    final diff = dateTime.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 1) return 'Expires in <1 min';
    if (diff.inHours < 1) return 'Expires in ${diff.inMinutes} min';
    if (diff.inDays < 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? 'Expires in ${h}h ${m}m' : 'Expires in ${h}h';
    }
    return 'Best before ${diff.inDays}d';
  }

  int _discountPercent() {
    if (item.originalPrice != null &&
        item.discountedPrice != null &&
        item.originalPrice! > 0) {
      return (((item.originalPrice! - item.discountedPrice!) /
                  item.originalPrice!) *
              100)
          .round();
    }
    return 50;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(item.imagePath);
    final countdown = _countdown(item.bestBefore);
    final isExpiring =
        item.bestBefore != null &&
        item.bestBefore!.difference(DateTime.now()).inHours < 2 &&
        !item.bestBefore!.isBefore(DateTime.now());
    final discountPct = _discountPercent();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Image (or emoji fallback) ─────────────────────────
              _buildHeroImage(imageUrl, discountPct, isExpiring, countdown),

              // ── Card Body ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Business name + posted-ago row
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.donorBusinessName ??
                                item.pickupAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (item.postedAgo.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.postedAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Pickup address (only if we already showed business name above)
                    if (item.donorBusinessName != null &&
                        item.donorBusinessName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.pickupAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Info chips row: quantity, serves, pickup window
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _infoChip(
                            Icons.inventory_2_outlined,
                            '${item.quantity} ${item.quantityUnit}',
                          ),
                          const SizedBox(width: 6),
                          _infoChip(
                            Icons.people_outline,
                            item.servesApprox,
                          ),
                          const SizedBox(width: 6),
                          _infoChip(
                            Icons.schedule_outlined,
                            'Pickup: ${item.pickupWindow}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 10),

                    // Price row + reserve button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (item.originalPrice != null) ...[
                              Text(
                                'Rs ${item.originalPrice!.toInt()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              'Rs ${(item.discountedPrice ?? 150).toInt()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryEmerald,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Reserve Deal →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    String? imageUrl,
    int discountPct,
    bool isExpiring,
    String? countdown,
  ) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or emoji placeholder
            if (imageUrl != null)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.cardLightBg,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: AppColors.primaryEmerald,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _emojiPlaceholder(),
              )
            else
              _emojiPlaceholder(),

            // Subtle dark gradient at the bottom to keep text legible
            if (imageUrl != null)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x66000000)],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),

            // Discount badge — top-left
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$discountPct% OFF',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Category label — top-right
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category == FoodCategory.veg
                      ? '🌱 Veg'
                      : item.category == FoodCategory.nonVeg
                          ? '🍗 Non-Veg'
                          : '🥐 Mixed',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // Best-before / expiry countdown — bottom-left
            if (countdown != null)
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpiring
                        ? const Color(0xFFE53935).withValues(alpha: 0.9)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpiring
                            ? Icons.warning_amber_rounded
                            : Icons.timer_outlined,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        countdown,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPlaceholder() {
    return Container(
      color: AppColors.cardLightBg,
      alignment: Alignment.center,
      child: Text(
        _categoryEmoji(item.category),
        style: const TextStyle(fontSize: 52),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
