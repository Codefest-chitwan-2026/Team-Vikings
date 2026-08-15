import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';

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
  final String? qrCode;
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
    this.qrCode,
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
    _claims = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClaims();
    });
  }

  Future<void> _fetchClaims() async {
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      await context.read<DonationProvider>().fetchClaims(token: token);
    }
    _loadDynamicClaims();
  }

  void _loadDynamicClaims() {
    final donationProvider = context.read<DonationProvider>();
    final List<_ClaimedDonation> dynamicClaims = [];

    for (final raw in donationProvider.claims) {
      if (raw is Map<String, dynamic>) {
        final id = (raw['id'] ?? '').toString();
        final donationData = raw['donation_details'] is Map<String, dynamic>
            ? raw['donation_details'] as Map<String, dynamic>
            : (raw['donation'] is Map<String, dynamic> ? raw['donation'] as Map<String, dynamic> : null);

        final title = (donationData?['title'] ?? raw['food_title'] ?? 'Rescued Surplus Food').toString();
        final donorName = (donationData?['donor_name'] ?? raw['donor_name'] ?? 'Verified Food Business').toString();
        final donorPhone = (donationData?['donor_phone'] ?? raw['donor_phone'] ?? '').toString();
        final pickupAddress = (donationData?['pickup_address'] ?? raw['pickup_address'] ?? 'Kathmandu').toString();

        final ticketMap = raw['pickup_ticket'] is Map<String, dynamic> ? raw['pickup_ticket'] as Map<String, dynamic> : null;
        final qrCode = ticketMap?['qr_code']?.toString() ?? raw['qr_code']?.toString();
        final code = raw['manual_code']?.toString() ?? qrCode ?? 'CLM-$id';

        final statusStr = (raw['status'] ?? '').toString().toUpperCase();
        final isTicketVerified = ticketMap?['is_verified'] == true;
        final isCompleted = isTicketVerified || statusStr == 'COMPLETED' || statusStr == 'PICKED_UP';

        final foodTypeStr = (donationData?['food_type'] ?? '').toString().toUpperCase();
        final cat = foodTypeStr.contains('NON')
            ? FoodCategory.nonVeg
            : (foodTypeStr.contains('MIX') ? FoodCategory.mixed : FoodCategory.veg);

        dynamicClaims.add(
          _ClaimedDonation(
            id: id,
            title: title,
            donorName: donorName,
            donorPhone: donorPhone,
            pickupAddress: pickupAddress,
            area: pickupAddress.split(',').first.trim(),
            distanceKm: double.tryParse(donationData?['distance_km']?.toString() ?? '1.2') ?? 1.2,
            quantity: int.tryParse(donationData?['quantity']?.toString() ?? '10') ?? 10,
            quantityUnit: (donationData?['quantity_unit'] ?? 'Plates').toString(),
            category: cat,
            claimCode: code,
            qrCode: qrCode,
            claimedAt: DateTime.tryParse(raw['claimed_at']?.toString() ?? raw['created_at']?.toString() ?? '') ?? DateTime.now(),
            pickupWindowMinutes: 45,
            description: donationData?['description']?.toString() ?? 'Verified surplus food rescue.',
            instructions: 'Show your Claim Code $code upon arrival for contactless verification.',
            status: isCompleted ? ClaimStatus.completed : ClaimStatus.readyForPickup,
          ),
        );
      }
    }

    setState(() {
      _claims = dynamicClaims;
    });
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
            claim.donorName.toLowerCase().contains(query) ||
            claim.claimCode.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  void _showPickupQrDialog(_ClaimedDonation claim) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pickup Ticket',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(ctx).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 110,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'VERIFICATION CODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    claim.claimCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryEmerald,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              claim.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${claim.quantity} ${claim.quantityUnit} · from ${claim.donorName}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryEmerald),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Present this ticket code or QR to the donor store for verification upon arrival.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20), height: 1.3),
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

  void _callDonor(_ClaimedDonation claim) {
    if (claim.donorPhone.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${claim.donorName} at ${claim.donorPhone}…'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact info for ${claim.donorName}: Please visit ${claim.pickupAddress}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final claims = _filteredClaims;
    final activeCount = _claims.where((c) => c.isActive).length;
    final completedCount = _claims.where((c) => !c.isActive).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchClaims,
        color: AppColors.primaryEmerald,
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
                      hintText: 'Search by food, donor, or claim code...',
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
              child: donationProvider.isLoading && _claims.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryEmerald),
                    )
                  : claims.isEmpty
                      ? Center(
                          child: EmptyStateWidget(
                            icon: Icons.volunteer_activism_outlined,
                            title: 'No Claimed Food Donations',
                            description:
                                'Your organization has not claimed any surplus food donations yet. Browse priority listings to claim meals for your community.',
                            buttonText: 'Refresh Claims',
                            buttonIcon: Icons.refresh_rounded,
                            onButtonPressed: _fetchClaims,
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

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPickupQrDialog(claim),
        child: Container(
          decoration: BoxDecoration(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Row & Claim Code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${claim.claimCode.substring(0, 10)}..',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
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
                        onPressed: () => _showPickupQrDialog(claim),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Show Pickup QR',
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
      ),
    );
  }
}
