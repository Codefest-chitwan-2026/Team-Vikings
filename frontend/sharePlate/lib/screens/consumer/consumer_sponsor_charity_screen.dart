import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/surplus_sponsor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sponsorship_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';

class ConsumerSponsorCharityScreen extends StatefulWidget {
  const ConsumerSponsorCharityScreen({super.key});

  @override
  State<ConsumerSponsorCharityScreen> createState() =>
      _ConsumerSponsorCharityScreenState();
}

class _ConsumerSponsorCharityScreenState
    extends State<ConsumerSponsorCharityScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _userSponsorships = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    final sp = context.read<SponsorshipProvider>();
    await sp.fetchSponsorshipItems(token: token);
    if (token != null && token.isNotEmpty) {
      await sp.fetchMySponsorships(token: token);
      final mySps = sp.mySponsorships;
      setState(() {
        _userSponsorships.clear();
        for (final s in mySps) {
          if (s is Map<String, dynamic>) {
            _userSponsorships.add({
              'id': (s['id'] ?? 'SPN-${s.hashCode.abs()}').toString(),
              'foodTitle': (s['food_title'] ?? 'Surplus Meal Package').toString(),
              'donorName': (s['donor_name'] ?? 'Restaurant Partner').toString(),
              'mealsCount': int.tryParse(s['meals_count']?.toString() ?? '10') ?? 10,
              'amount': double.tryParse(s['amount']?.toString() ?? '800')?.round() ?? 800,
              'originalValue': double.tryParse(s['original_value']?.toString() ?? '3000')?.round() ?? 3000,
              'savings': double.tryParse(s['savings']?.toString() ?? '2200')?.round() ?? 2200,
              'date': s['created_at'] != null ? s['created_at'].toString().split('T').first : 'Recently',
              'status': (s['status'] ?? 'CONFIRMED').toString().toUpperCase() == 'CONFIRMED'
                  ? 'Sponsorship Confirmed'
                  : 'Processing',
              'dedication': (s['dedication'] ?? '').toString(),
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SurplusSponsorItem> get _filteredItems {
    final providerItems = context.watch<SponsorshipProvider>().items;
    if (_searchQuery.isEmpty) {
      return providerItems;
    }
    final query = _searchQuery.toLowerCase();
    return providerItems.where((item) {
      return item.foodTitle.toLowerCase().contains(query) ||
          item.donorName.toLowerCase().contains(query) ||
          item.donorAddress.toLowerCase().contains(query);
    }).toList();
  }

  void _openQuickSponsorModal(SurplusSponsorItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSponsorBottomSheet(
        item: item,
        onSponsorSuccess: (newSponsorship) {
          setState(() {
            _userSponsorships.insert(0, newSponsorship);
          });
          _showConfirmationDialog(newSponsorship);
        },
      ),
    );
  }

  void _openMySponsorships() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MySponsorshipsHistorySheet(sponsorships: _userSponsorships),
    );
  }

  void _showConfirmationDialog(Map<String, dynamic> sponsorship) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: AppColors.primaryEmerald,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sponsorship Successful! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You just sponsored the entire batch of ${sponsorship['mealsCount']} surplus meals from ${sponsorship['donorName']}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sponsorship ID',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          sponsorship['id'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Paid via eSewa',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Rs. ${sponsorship['amount']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItems;
    final totalUserMeals = _userSponsorships.fold<int>(
      0,
      (sum, item) => sum + (item['mealsCount'] as int),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Donor Surplus Rescue',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sponsor Surplus Meals',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _openMySponsorships,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 18,
                              color: AppColors.primaryEmerald,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$totalUserMeals Meals',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                    decoration: InputDecoration(
                      hintText: 'Search surplus meals, hotel or locality...',
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
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
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Surplus Batches',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${list.length} Batches listed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Flash Card List
            if (list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyStateWidget(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'No Surplus Food Packages',
                    description:
                        'All surplus meals have currently been claimed or sponsored! Check back later as restaurants add new packages.',
                    buttonText: 'Refresh Packages',
                    buttonIcon: Icons.refresh_rounded,
                    onButtonPressed: _fetchData,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = list[index];
                      return _SurplusFoodFlashCard(
                        item: item,
                        onSponsorTap: () => _openQuickSponsorModal(item),
                      );
                    },
                    childCount: list.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Clean Flash Card for a donor's surplus food batch available for sponsoring
class _SurplusFoodFlashCard extends StatelessWidget {
  const _SurplusFoodFlashCard({
    required this.item,
    required this.onSponsorTap,
  });

  final SurplusSponsorItem item;
  final VoidCallback onSponsorTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSponsorTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header Strip with Donor Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.bannerGradient,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hotel_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.donorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.discountPercent}% OFF',
                    style: const TextStyle(
                      color: Color(0xFF3E2723),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Title
                Text(
                  item.foodTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 10),

                // Batch quantity tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: AppColors.primaryEmerald,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Entire Batch: ${item.remainingMeals} ${item.quantityUnit} Available',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),

                // Pricing Row & Action Buttons
                Row(
                  children: [
                    // Price for Sponsoring Entire Batch
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sponsor Entire Batch',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Rs. ${item.totalSponsorPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Rs. ${item.totalOriginalPrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '(Rs. ${item.sponsorPricePerMeal.toInt()} / meal)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Sponsor Entire Batch Action Button
                    ElevatedButton.icon(
                      onPressed: onSponsorTap,
                      icon: const Icon(Icons.volunteer_activism, size: 15),
                      label: const Text(
                        'Sponsor Batch',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
}

/// Quick Sponsor Bottom Sheet (Whole Meal Batch Only with eSewa)
class _QuickSponsorBottomSheet extends StatefulWidget {
  const _QuickSponsorBottomSheet({
    required this.item,
    required this.onSponsorSuccess,
  });

  final SurplusSponsorItem item;
  final ValueChanged<Map<String, dynamic>> onSponsorSuccess;

  @override
  State<_QuickSponsorBottomSheet> createState() =>
      _QuickSponsorBottomSheetState();
}

class _QuickSponsorBottomSheetState extends State<_QuickSponsorBottomSheet> {
  bool _isAnonymous = false;
  bool _isProcessing = false;
  final TextEditingController _dedicationController = TextEditingController();

  @override
  void dispose() {
    _dedicationController.dispose();
    super.dispose();
  }

  int get _mealsCount => widget.item.remainingMeals;
  double get _totalPrice => widget.item.totalSponsorPrice;

  Future<void> _handleConfirm() async {
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sponsorshipProvider = Provider.of<SponsorshipProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final token = user?.token;
    final userName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : (user?.name.isNotEmpty == true ? user!.name : 'Rojina Shrestha');

    final dedication = _dedicationController.text.trim().isNotEmpty
        ? _dedicationController.text.trim()
        : (_isAnonymous ? 'Anonymous Sponsor' : 'Dedicated by $userName');
    if (token != null && token.isNotEmpty) {
      await sponsorshipProvider.createSponsorship(
        token: token,
        surplusItemId: widget.item.id,
        foodTitle: widget.item.foodTitle,
        donorName: widget.item.donorName,
        mealsCount: _mealsCount,
        amount: _totalPrice,
        originalValue: widget.item.totalOriginalPrice,
        dedication: dedication,
      );
    }

    if (!mounted) return;

    final newSponsorship = {
      'id': 'SPN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'surplusId': widget.item.id,
      'foodTitle': widget.item.foodTitle,
      'donorName': widget.item.donorName,
      'mealsCount': _mealsCount,
      'amount': _totalPrice.round(),
      'date': 'Just now',
      'status': 'Sponsorship Confirmed',
      'dedication': dedication,
      'paymentMethod': 'eSewa Mobile Wallet',
    };

    Navigator.of(context).pop();
    widget.onSponsorSuccess(newSponsorship);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sponsor ${widget.item.donorName}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.foodTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.charcoal),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                children: [
                  // Sponsoring package details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryEmerald.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.volunteer_activism_rounded,
                          color: AppColors.primaryEmerald,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sponsoring Entire Batch: $_mealsCount ${widget.item.quantityUnit}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rate: Rs. ${widget.item.sponsorPricePerMeal.toInt()} / meal (Subsidized from Rs. ${widget.item.originalPricePerMeal.toInt()})',
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
                  ),

                  const SizedBox(height: 16),

                  // Dedication note
                  const Text(
                    'Dedication Note (Optional)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dedicationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Birthday dedication, in memory of...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryEmerald,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAnonymous,
                        activeColor: AppColors.primaryEmerald,
                        onChanged: (val) {
                          setState(() => _isAnonymous = val ?? false);
                        },
                      ),
                      const Text(
                        'Sponsor anonymously',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Payment method: eSewa only
                  const Text(
                    'Payment Partner',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryEmerald,
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text('🟢', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'eSewa Mobile Wallet',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryEmerald,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All $_mealsCount Meals',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Rs. ${_totalPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Pay Rs. ${_totalPrice.toInt()} with eSewa',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// My Sponsorships History Sheet
class _MySponsorshipsHistorySheet extends StatelessWidget {
  const _MySponsorshipsHistorySheet({required this.sponsorships});

  final List<Map<String, dynamic>> sponsorships;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Sponsored Surplus History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.charcoal),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: sponsorships.isEmpty
                  ? Center(
                      child: EmptyStateWidget(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'No Sponsorships Yet',
                        description:
                            'You haven\'t sponsored any surplus meal packages yet. Sponsoring directly funds food redirection to communities in need.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: sponsorships.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = sponsorships[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['donorName'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${item['amount']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['mealsCount']} Meals Batch · ${item['foodTitle']}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['date'] as String,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['status'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryEmerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
