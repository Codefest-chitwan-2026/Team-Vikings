import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';

class RecipientClaimedDonationsScreen extends StatefulWidget {
  const RecipientClaimedDonationsScreen({super.key});

  @override
  State<RecipientClaimedDonationsScreen> createState() =>
      _RecipientClaimedDonationsScreenState();
}

enum _ClaimFilter { all, active, completed }

enum ClaimStatus { readyForPickup, enRoute, completed }

class _ClaimedDonation {
  final String id;
  final String title;
  final String donorName;
  final String donorPhone;
  final String pickupAddress;
  final String area;
  final double distanceKm;
  final int quantity;
  final String quantityUnit;
  final FoodCategory category;
  final String claimCode;
  final DateTime claimedAt;
  final int pickupWindowMinutes;
  final String description;
  final String instructions;
  ClaimStatus status;

  _ClaimedDonation({
    required this.id,
    required this.title,
    required this.donorName,
    required this.donorPhone,
    required this.pickupAddress,
    required this.area,
    required this.distanceKm,
    required this.quantity,
    required this.quantityUnit,
    required this.category,
    required this.claimCode,
    required this.claimedAt,
    required this.pickupWindowMinutes,
    required this.description,
    required this.instructions,
    this.status = ClaimStatus.readyForPickup,
  });

  bool get isActive =>
      status == ClaimStatus.readyForPickup ||
      status == ClaimStatus.enRoute;
}

class _RecipientClaimedDonationsScreenState
    extends State<RecipientClaimedDonationsScreen> {
  _ClaimFilter _selectedFilter = _ClaimFilter.all;
  String _searchQuery = '';

  late List<_ClaimedDonation> _claims;

  @override
  void initState() {
    super.initState();
    _claims = [
      _ClaimedDonation(
        id: 'claim-1',
        title: 'Dal Bhat & Mixed Curry Trays',
        donorName: 'Hotel Annapurna Kitchen',
        donorPhone: '9841234567',
        pickupAddress: 'Lazimpat, Kathmandu',
        area: 'Lazimpat',
        distanceKm: 1.2,
        quantity: 18,
        quantityUnit: 'Trays',
        category: FoodCategory.veg,
        claimCode: 'CLM-7842',
        claimedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        pickupWindowMinutes: 45,
        description:
            'Freshly cooked rice, dal and seasonal vegetable curry from dinner buffet.',
        instructions: 'Enter via rear kitchen loading dock and ask for Head Chef Ram.',
        status: ClaimStatus.readyForPickup,
      ),
      _ClaimedDonation(
        id: 'claim-2',
        title: 'Freshly Baked Wholewheat Breads & Rolls',
        donorName: 'Himalayan Bakers & Cafe',
        donorPhone: '9801987654',
        pickupAddress: 'Jhamsikhel, Lalitpur',
        area: 'Jhamsikhel',
        distanceKm: 2.8,
        quantity: 15,
        quantityUnit: 'Packs',
        category: FoodCategory.veg,
        claimCode: 'CLM-3319',
        claimedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        pickupWindowMinutes: 60,
        description: 'Packaged sandwich loaves, baguettes and dinner rolls baked this morning.',
        instructions: 'Collect from bakery front counter. Present your Claim Code.',
        status: ClaimStatus.readyForPickup,
      ),
      _ClaimedDonation(
        id: 'claim-3',
        title: 'Mixed Vegetable Pulao & Paneer Gravy',
        donorName: 'Royal Banquet Hall',
        donorPhone: '9851098765',
        pickupAddress: 'Baluwatar, Kathmandu',
        area: 'Baluwatar',
        distanceKm: 3.5,
        quantity: 30,
        quantityUnit: 'Portions',
        category: FoodCategory.veg,
        claimCode: 'CLM-1094',
        claimedAt: DateTime.now().subtract(const Duration(hours: 6)),
        pickupWindowMinutes: 90,
        description: 'Surplus food from afternoon reception. Stored in hot containers.',
        instructions: 'Picked up and distributed at Central Community Kitchen.',
        status: ClaimStatus.completed,
      ),
    ];
  }

  List<_ClaimedDonation> get _filteredClaims {
    return _claims.where((claim) {
      if (_selectedFilter == _ClaimFilter.active && !claim.isActive) {
        return false;
      }
      if (_selectedFilter == _ClaimFilter.completed && claim.isActive) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return claim.title.toLowerCase().contains(query) ||
            claim.donorName.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  void _confirmPickup(_ClaimedDonation claim) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppColors.primaryEmerald),
            SizedBox(width: 8),
            Text('Confirm Pickup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Have you successfully collected ${claim.quantity} ${claim.quantityUnit.toLowerCase()} of "${claim.title}" from ${claim.donorName}?',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Yet', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                claim.status = ClaimStatus.completed;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Marked "${claim.title}" as collected. Great rescue!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Yes, Picked Up', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _callDonor(_ClaimedDonation claim) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${claim.donorName} at ${claim.donorPhone}…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claims = _filteredClaims;
    final activeCount = _claims.where((c) => c.isActive).length;
    final completedCount = _claims.where((c) => !c.isActive).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Claimed Donations',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Track active food pickups & distribution',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by food or donor...',
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
                const SizedBox(height: 12),

                // Filter Tabs
                Row(
                  children: [
                    _filterButton('All (${_claims.length})', _ClaimFilter.all),
                    const SizedBox(width: 8),
                    _filterButton('Ready for Pickup ($activeCount)', _ClaimFilter.active),
                    const SizedBox(width: 8),
                    _filterButton('Completed ($completedCount)', _ClaimFilter.completed),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Claims List
          Expanded(
            child: claims.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No claimed donations found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Claim surplus food listings from the Browse or Home tab to see them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: claims.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final claim = claims[index];
                      return _buildClaimCard(claim);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, _ClaimFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryEmerald : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryEmerald : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimCard(_ClaimedDonation claim) {
    final isActive = claim.isActive;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primaryEmerald.withValues(alpha: 0.35)
              : AppColors.border,
          width: isActive ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE4F6E9)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.hourglass_top_rounded
                            : Icons.check_circle_rounded,
                        size: 13,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Ready for Pickup' : 'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Food Title & Quantity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${claim.quantity} ${claim.quantityUnit} · ${claim.category.label}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Donor & Location
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          claim.donorName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${claim.distanceKm.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          claim.pickupAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isActive) ...[
              const SizedBox(height: 10),
              // Pickup Window
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Text(
                    'Pickup window: ${claim.pickupWindowMinutes} mins remaining',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callDonor(claim),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.charcoal),
                      label: const Text(
                        'Call',
                        style: TextStyle(fontSize: 12, color: AppColors.charcoal, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmPickup(claim),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Confirm Pickup',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
