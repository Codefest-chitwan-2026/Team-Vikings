import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFlashSales();
    });
  }

  Future<void> _loadFlashSales() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      await context.read<DonationProvider>().fetchFlashSales(token: token);
    }
  }

  List<DonationItem> _getFilteredSales(List<DonationItem> flashSales) {
    return flashSales.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesAddress = item.pickupAddress.toLowerCase().contains(query);
        return matchesTitle || matchesAddress;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final list = _getFilteredSales(donationProvider.flashSaleDonations);
    final isLoading = donationProvider.isLoading;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flash Deals ⚡',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Rescue premium meals at up to 70% off',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryEmerald),
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
                              builder: (_) => const ConsumerNotificationsScreen(),
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search discount food, cafe, locality...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sponsor Charity Food Banner
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
                        color: AppColors.primaryEmerald.withValues(alpha: 0.15),
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
                        horizontal: 10,
                        vertical: 6,
                      ),
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

          // Category Chips
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

          // Deals List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
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
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, idx) {
                            final item = list[idx];
                            return _FlashSaleCard(
                              item: item,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ConsumerDealDetailScreen(deal: item),
                                ),
                              ),
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
            color: isSelected ? AppColors.primaryEmerald : AppColors.border,
          ),
        ),
        onSelected: (_) => setState(() => _selectedCategory = cat),
      ),
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({required this.item, required this.onTap});

  final DonationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discountPercent = (item.originalPrice != null &&
            item.discountedPrice != null &&
            item.originalPrice! > 0)
        ? (((item.originalPrice! - item.discountedPrice!) / item.originalPrice!) * 100).round()
        : 50;

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.cardLightBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.category == FoodCategory.veg ? '🥗' : (item.category == FoodCategory.nonVeg ? '🍗' : '🥐'),
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.pickupAddress} · ${item.servesApprox}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$discountPercent% OFF',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (item.originalPrice != null)
                        Text(
                          'Rs ${item.originalPrice!.toInt()}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (item.originalPrice != null) const SizedBox(width: 8),
                      Text(
                        'Rs ${(item.discountedPrice ?? 150).toInt()}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryEmerald,
                      borderRadius: BorderRadius.circular(8),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
