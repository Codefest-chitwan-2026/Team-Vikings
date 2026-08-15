import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';

// ─── Filter enum ────────────────────────────────────────────────────────────

enum _ClaimFilter { all, active, completed }

// ─── Claim view-model (built fresh from raw API map every build) ────────────

class _ClaimVM {
  _ClaimVM._({
    required this.id,
    required this.title,
    required this.donorName,
    required this.donorPhone,
    required this.pickupAddress,
    required this.quantity,
    required this.quantityUnit,
    required this.category,
    required this.claimCode,
    required this.qrCode,
    required this.claimedAt,
    required this.pickupWindowMinutes,
    required this.description,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String donorName;
  final String donorPhone;
  final String pickupAddress;
  final int quantity;
  final String quantityUnit;
  final FoodCategory category;
  final String claimCode;
  final String? qrCode;
  final DateTime claimedAt;
  final int pickupWindowMinutes;
  final String description;
  final bool isCompleted;

  bool get isActive => !isCompleted;

  /// Parse one raw claim map from the backend into a view-model.
  factory _ClaimVM.fromRaw(Map<String, dynamic> raw) {
    final id = (raw['id'] ?? '').toString();

    // The donation details may be nested under different keys depending on
    // which serializer the backend uses.
    final donationData = raw['donation_details'] is Map<String, dynamic>
        ? raw['donation_details'] as Map<String, dynamic>
        : raw['donation'] is Map<String, dynamic>
            ? raw['donation'] as Map<String, dynamic>
            : <String, dynamic>{};

    final title =
        (donationData['title'] ?? raw['food_title'] ?? 'Rescued Surplus Food')
            .toString();
    final donorName =
        (donationData['donor_name'] ?? raw['donor_name'] ?? 'Verified Food Business')
            .toString();
    final donorPhone = (donationData['donor_phone'] ??
            raw['donor_phone'] ??
            raw['ngo_details']?['phone'] ??
            '')
        .toString();
    final pickupAddress =
        (donationData['pickup_address'] ?? raw['pickup_address'] ?? 'Kathmandu')
            .toString();

    // Pickup ticket / QR
    final ticketMap = raw['pickup_ticket'] is Map<String, dynamic>
        ? raw['pickup_ticket'] as Map<String, dynamic>
        : null;
    final qrCode =
        ticketMap?['qr_code']?.toString() ?? raw['qr_code']?.toString();
    final claimCode = raw['manual_code']?.toString() ?? qrCode ?? 'CLM-$id';

    // Status
    final statusStr = (raw['status'] ?? '').toString().toUpperCase();
    final isTicketVerified = ticketMap?['is_verified'] == true;
    final isCompleted = isTicketVerified ||
        statusStr == 'COMPLETED' ||
        statusStr == 'PICKED_UP' ||
        statusStr == 'DELIVERED';

    // Food type → category
    final foodTypeStr =
        (donationData['food_type'] ?? raw['food_type'] ?? '').toString().toUpperCase();
    final cat = foodTypeStr.contains('NON')
        ? FoodCategory.nonVeg
        : foodTypeStr.contains('MIX')
            ? FoodCategory.mixed
            : FoodCategory.veg;

    // Timestamp
    final claimedAt = DateTime.tryParse(
          raw['claimed_at']?.toString() ??
              raw['created_at']?.toString() ??
              '',
        ) ??
        DateTime.now();

    // Quantity
    final qty =
        int.tryParse(donationData['quantity']?.toString() ?? '10') ?? 10;
    final unit = (donationData['quantity_unit'] ?? 'Plates').toString();

    // Pickup window: try to derive from raw JSON, fallback 45 min
    int winMins = 45;
    final detail = raw['listing_detail'] is Map<String, dynamic>
        ? raw['listing_detail'] as Map<String, dynamic>
        : donationData['listing_detail'] is Map<String, dynamic>
            ? donationData['listing_detail'] as Map<String, dynamic>
            : null;
    if (detail?['pickup_window_start'] != null &&
        detail?['pickup_window_end'] != null) {
      try {
        final start =
            DateTime.parse(detail!['pickup_window_start'].toString());
        final end = DateTime.parse(detail['pickup_window_end'].toString());
        winMins = end.difference(start).inMinutes.clamp(15, 240);
      } catch (_) {}
    } else if (raw['pickup_window_minutes'] != null) {
      winMins =
          int.tryParse(raw['pickup_window_minutes'].toString()) ?? winMins;
    }

    return _ClaimVM._(
      id: id,
      title: title,
      donorName: donorName,
      donorPhone: donorPhone,
      pickupAddress: pickupAddress,
      quantity: qty,
      quantityUnit: unit,
      category: cat,
      claimCode: claimCode,
      qrCode: qrCode,
      claimedAt: claimedAt,
      pickupWindowMinutes: winMins,
      description: donationData['description']?.toString() ??
          'Verified surplus food rescue.',
      isCompleted: isCompleted,
    );
  }
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class RecipientClaimedDonationsScreen extends StatefulWidget {
  const RecipientClaimedDonationsScreen({super.key});

  @override
  State<RecipientClaimedDonationsScreen> createState() =>
      _RecipientClaimedDonationsScreenState();
}

class _RecipientClaimedDonationsScreenState
    extends State<RecipientClaimedDonationsScreen> {
  _ClaimFilter _selectedFilter = _ClaimFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchClaims());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClaims() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;
    if (token != null && token.isNotEmpty) {
      await context.read<DonationProvider>().fetchClaims(token: token);
    }
  }

  /// Convert raw provider list → typed view-models, applying filter + search.
  /// Deduplicates by claim id so the same claim never appears twice even if
  /// the provider list contains duplicate entries.
  List<_ClaimVM> _buildFilteredList(List<dynamic> rawClaims) {
    final seen = <String>{};
    final all = rawClaims
        .whereType<Map<String, dynamic>>()
        .map(_ClaimVM.fromRaw)
        .where((vm) => seen.add(vm.id)) // dedup — only keep first occurrence
        .toList();

    return all.where((c) {
      // Filter tab
      if (_selectedFilter == _ClaimFilter.active && !c.isActive) return false;
      if (_selectedFilter == _ClaimFilter.completed && c.isActive) return false;

      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.title.toLowerCase().contains(q) ||
            c.donorName.toLowerCase().contains(q) ||
            c.claimCode.toLowerCase().contains(q) ||
            c.pickupAddress.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _showPickupTicket(_ClaimVM claim) {
    showDialog(
      context: context,
      builder: (ctx) => _PickupTicketDialog(claim: claim),
    );
  }

  void _callDonor(_ClaimVM claim) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          claim.donorPhone.isNotEmpty
              ? 'Calling ${claim.donorName} at ${claim.donorPhone}…'
              : 'Contact: ${claim.pickupAddress}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DonationProvider>();
    final rawClaims = provider.claims;

    // Build full list once for counts (deduplicated), filtered list for display
    final seenIds = <String>{};
    final allVMs = rawClaims
        .whereType<Map<String, dynamic>>()
        .map(_ClaimVM.fromRaw)
        .where((vm) => seenIds.add(vm.id))
        .toList();
    final activeCount = allVMs.where((c) => c.isActive).length;
    final completedCount = allVMs.where((c) => !c.isActive).length;
    final displayList = _buildFilteredList(rawClaims);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchClaims,
        color: AppColors.primaryEmerald,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Claimed Donations',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Track active food pickups & distribution',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Live count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primaryEmerald
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                                Icons.volunteer_activism_rounded,
                                size: 15,
                                color: AppColors.primaryEmerald),
                            const SizedBox(width: 5),
                            Text(
                              '${allVMs.length}',
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
                  const SizedBox(height: 16),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim()),
                    decoration: InputDecoration(
                      hintText:
                          'Search by food, donor, or claim code…',
                      hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search,
                          size: 20,
                          color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(
                                    () => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter tabs
                  Row(
                    children: [
                      _filterChip('All (${allVMs.length})',
                          _ClaimFilter.all),
                      const SizedBox(width: 8),
                      _filterChip('Active ($activeCount)',
                          _ClaimFilter.active),
                      const SizedBox(width: 8),
                      _filterChip('Done ($completedCount)',
                          _ClaimFilter.completed),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── List ───────────────────────────────────────────────
            Expanded(
              child: provider.isLoading && rawClaims.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryEmerald))
                  : displayList.isEmpty
                      ? Center(
                          child: EmptyStateWidget(
                            icon: Icons
                                .volunteer_activism_outlined,
                            title: provider.errorMessage != null
                                ? 'Couldn\'t Load Claims'
                                : _searchQuery.isNotEmpty ||
                                        _selectedFilter !=
                                            _ClaimFilter.all
                                    ? 'No Matching Claims'
                                    : 'No Claimed Donations Yet',
                            description: provider.errorMessage ??
                                (_searchQuery.isNotEmpty
                                    ? 'No claims match your search. Try different keywords.'
                                    : _selectedFilter ==
                                            _ClaimFilter.active
                                        ? 'You have no active pickups right now.'
                                        : _selectedFilter ==
                                                _ClaimFilter
                                                    .completed
                                            ? 'No completed claims yet.'
                                            : 'Your organisation has not claimed any surplus food donations yet. Browse priority listings to claim meals for your community.'),
                            buttonText: 'Refresh',
                            buttonIcon: Icons.refresh_rounded,
                            onButtonPressed: _fetchClaims,
                          ),
                        )
                      : ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                              20, 4, 20, 24),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (ctx, i) {
                            final claim = displayList[i];
                            return _ClaimCard(
                              claim: claim,
                              onShowTicket: () =>
                                  _showPickupTicket(claim),
                              onCall: () => _callDonor(claim),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _ClaimFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryEmerald
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryEmerald
                  : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Claim Card ──────────────────────────────────────────────────────────────

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.onShowTicket,
    required this.onCall,
  });

  final _ClaimVM claim;
  final VoidCallback onShowTicket;
  final VoidCallback onCall;

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

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = claim.isActive;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isActive ? onShowTicket : null,
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
              // ── Top row: claim code + status badge ──────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      claim.claimCode.length > 12
                          ? '${claim.claimCode.substring(0, 12)}…'
                          : claim.claimCode,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(claim.claimedAt),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
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
                          size: 12,
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive
                              ? 'Ready for Pickup'
                              : 'Completed',
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

              // ── Food title + category ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.cardLightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categoryEmoji(claim.category),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claim.title,
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
                          '${claim.quantity} ${claim.quantityUnit} · ${claim.category.label}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Donor + address info box ─────────────────────────
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
                            size: 15,
                            color: AppColors.textSecondary),
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            claim.pickupAddress,
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
                    if (isActive) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 15,
                              color: Color(0xFFE65100)),
                          const SizedBox(width: 8),
                          Text(
                            'Pickup window: ${claim.pickupWindowMinutes} min',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Action buttons (active only) ─────────────────────
              if (isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCall,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          side: const BorderSide(
                              color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                            Icons.phone_outlined,
                            size: 15,
                            color: AppColors.charcoal),
                        label: const Text(
                          'Call',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onShowTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryEmerald,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                            Icons.qr_code_rounded,
                            size: 15,
                            color: Colors.white),
                        label: const Text(
                          'Show Pickup QR',
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

              // ── Completed row ────────────────────────────────────
              if (!isActive) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 15,
                        color: AppColors.primaryEmerald),
                    const SizedBox(width: 6),
                    const Text(
                      'Food successfully distributed',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryEmerald,
                        fontWeight: FontWeight.w600,
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

// ─── Pickup Ticket Dialog ─────────────────────────────────────────────────────

class _PickupTicketDialog extends StatelessWidget {
  const _PickupTicketDialog({required this.claim});

  final _ClaimVM claim;

  @override
  Widget build(BuildContext context) {
    final qr = claim.qrCode ?? claim.claimCode;

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pickup Ticket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // QR code container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Real QR rendered with qr_flutter
                  QrImageView(
                    data: qr,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.charcoal,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'VERIFICATION CODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    claim.claimCode,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryEmerald,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Food title + quantity
            Text(
              claim.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${claim.quantity} ${claim.quantityUnit} · from ${claim.donorName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Instruction banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.primaryEmerald),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Show this QR or code to the donor store for contactless verification.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B5E20),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
