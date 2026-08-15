import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';

enum _ClaimSource { all, ngo, customer, completed }

enum DonorClaimStatus { awaitingPickup, completed }

class _IncomingClaim {
  final String id;
  final String listingTitle;
  final String claimantName;
  final String claimantType; // 'NGO' or 'Customer'
  final String claimantPhone;
  final int quantity;
  final String quantityUnit;
  final FoodCategory category;
  final String verificationCode;
  final DateTime claimedAt;
  final int pickupWindowMinutes;
  final double? amountPaid;
  final String pickupNotes;
  DonorClaimStatus status;

  _IncomingClaim({
    required this.id,
    required this.listingTitle,
    required this.claimantName,
    required this.claimantType,
    required this.claimantPhone,
    required this.quantity,
    required this.quantityUnit,
    required this.category,
    required this.verificationCode,
    required this.claimedAt,
    required this.pickupWindowMinutes,
    this.amountPaid,
    required this.pickupNotes,
    this.status = DonorClaimStatus.awaitingPickup,
  });

  bool get isNgo => claimantType.toLowerCase() == 'ngo';
  bool get isActive => status == DonorClaimStatus.awaitingPickup;
}

class DonorClaimsManagementScreen extends StatefulWidget {
  const DonorClaimsManagementScreen({super.key});

  @override
  State<DonorClaimsManagementScreen> createState() =>
      _DonorClaimsManagementScreenState();
}

class _DonorClaimsManagementScreenState
    extends State<DonorClaimsManagementScreen> {
  _ClaimSource _selectedFilter = _ClaimSource.all;

  late List<_IncomingClaim> _claims;

  @override
  void initState() {
    super.initState();
    _claims = [
      _IncomingClaim(
        id: 'in-claim-1',
        listingTitle: 'Surplus Dal Bhat & Curry Buffet Trays',
        claimantName: 'Aasha Foundation Nepal',
        claimantType: 'NGO',
        claimantPhone: '9841234567',
        quantity: 18,
        quantityUnit: 'Trays',
        category: FoodCategory.veg,
        verificationCode: 'CLM-7842',
        claimedAt: DateTime.now().subtract(const Duration(minutes: 18)),
        pickupWindowMinutes: 45,
        pickupNotes: 'Volunteer van en route. Collecting via back kitchen dock.',
        status: DonorClaimStatus.awaitingPickup,
      ),
      _IncomingClaim(
        id: 'in-claim-2',
        listingTitle: 'Assorted Gourmet Pastry Box (4 pcs)',
        claimantName: 'Rojina Shrestha',
        claimantType: 'Customer',
        claimantPhone: '9860123456',
        quantity: 1,
        quantityUnit: 'Box',
        category: FoodCategory.veg,
        verificationCode: 'ORD-5542',
        amountPaid: 180,
        claimedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        pickupWindowMinutes: 35,
        pickupNotes: 'Paid online via Flash Sale. Collecting at cash counter.',
        status: DonorClaimStatus.awaitingPickup,
      ),
      _IncomingClaim(
        id: 'in-claim-3',
        listingTitle: 'Fresh Wholewheat Breads & Rolls',
        claimantName: 'Helping Hands Community Shelter',
        claimantType: 'NGO',
        claimantPhone: '9801987654',
        quantity: 12,
        quantityUnit: 'Packs',
        category: FoodCategory.veg,
        verificationCode: 'CLM-3319',
        claimedAt: DateTime.now().subtract(const Duration(hours: 3)),
        pickupWindowMinutes: 60,
        pickupNotes: 'Collected and verified by Driver Rajesh.',
        status: DonorClaimStatus.completed,
      ),
    ];
  }

  List<_IncomingClaim> get _filteredClaims {
    return _claims.where((claim) {
      if (_selectedFilter == _ClaimSource.ngo && (!claim.isNgo || !claim.isActive)) {
        return false;
      }
      if (_selectedFilter == _ClaimSource.customer && (claim.isNgo || !claim.isActive)) {
        return false;
      }
      if (_selectedFilter == _ClaimSource.completed && claim.isActive) {
        return false;
      }
      return true;
    }).toList();
  }

  void _verifyAndHandover(_IncomingClaim claim) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: AppColors.primaryEmerald),
            SizedBox(width: 8),
            Text('Verify & Hand Over', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Handing over "${claim.listingTitle}" to ${claim.claimantName}.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              'Ask claimant for verification code (Expected: ${claim.verificationCode}):',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter code e.g. ${claim.verificationCode}',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                claim.status = DonorClaimStatus.completed;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Handover verified! "${claim.listingTitle}" marked as collected by ${claim.claimantName}.',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm Handover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _callClaimant(_IncomingClaim claim) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${claim.claimantName} at ${claim.claimantPhone}…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claims = _filteredClaims;
    final activeCount = _claims.where((c) => c.isActive).length;
    final ngoCount = _claims.where((c) => c.isActive && c.isNgo).length;
    final customerCount = _claims.where((c) => c.isActive && !c.isNgo).length;
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Claims & Pickups',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage NGO rescues and customer orders',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz_rounded,
                              size: 15, color: AppColors.primaryEmerald),
                          const SizedBox(width: 5),
                          Text(
                            '$activeCount Active',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Stats
                // Row(
                //   children: [
                //     _buildStatCard('NGO Rescues', '$ngoCount active', Icons.volunteer_activism_outlined, const Color(0xFF2E7D32)),
                //     const SizedBox(width: 10),
                //     _buildStatCard('Flash Orders', '$customerCount active', Icons.local_offer_outlined, const Color(0xFFE65100)),
                //     const SizedBox(width: 10),
                //     _buildStatCard('Completed', '$completedCount total', Icons.done_all_rounded, const Color(0xFF1677D2)),
                //   ],
                // ),
                const SizedBox(height: 14),

                // Filter Buttons
                Row(
                  children: [
                    _filterButton('All (${_claims.length})', _ClaimSource.all),
                    const SizedBox(width: 6),
                    _filterButton('Remaining ($ngoCount)', _ClaimSource.ngo),
                    const SizedBox(width: 6),
                    _filterButton('Pending ($customerCount)', _ClaimSource.customer),
                    const SizedBox(width: 6),
                    _filterButton('Completed ($completedCount)', _ClaimSource.completed),
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
                      Icons.inbox_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No claims found in this view',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'When NGOs or customers claim your surplus food listings, they will appear here.',
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
                return _buildIncomingClaimCard(claim);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String subtitle, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, _ClaimSource filter) {
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

  Widget _buildIncomingClaimCard(_IncomingClaim claim) {
    final isActive = claim.isActive;
    final isNgo = claim.isNgo;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? (isNgo ? AppColors.primaryEmerald.withValues(alpha: 0.35) : const Color(0xFFFFB74D))
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
            // Header: Claimant Type Tag & Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNgo ? const Color(0xFFE4F6E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isNgo ? 'NGO Free Rescue' : 'Flash Sale Order',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isNgo ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFE4F6E9) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                        size: 12,
                        color: isActive ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isActive
                            ? (isNgo ? 'Ready' : 'Awaiting Pickup')
                            : 'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFF2E7D32) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Food Title
            Text(
              claim.listingTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${claim.quantity} ${claim.quantityUnit} · ${claim.category.label}${claim.amountPaid != null ? ' · Rs ${claim.amountPaid!.toInt()} paid' : ' · Free Donation'}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isNgo ? AppColors.primaryEmerald : const Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 10),

            // Claimant Details Box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isNgo ? Icons.business_outlined : Icons.person_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          claim.claimantName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Window: ${claim.pickupWindowMinutes}m',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  if (claim.pickupNotes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        claim.pickupNotes,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callClaimant(claim),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.phone_outlined, size: 16, color: AppColors.charcoal),
                      label: const Text(
                        'Call Claimant',
                        style: TextStyle(fontSize: 12, color: AppColors.charcoal, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _verifyAndHandover(claim),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Verify & Hand Over',
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