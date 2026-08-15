import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/listing_flow_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';
import 'add_donation_screen.dart';

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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late List<_IncomingClaim> _claims;

  @override
  void initState() {
    super.initState();
    _claims = [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final token = auth.currentUser?.token;
      if (token != null && token.isNotEmpty) {
        context.read<DonationProvider>().fetchClaims(token: token).then((_) {
          _loadDynamicClaims();
        });
        context.read<DonationProvider>().fetchDonations(token: token).then((_) {
          _loadDynamicClaims();
        });
      } else {
        _loadDynamicClaims();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDynamicClaims() {
    final donationProvider = context.read<DonationProvider>();
    final List<_IncomingClaim> dynamicClaims = [];


    for (final item in [
      ...donationProvider.activeDonations,
      ...donationProvider.pastDonations
    ]) {
      if (item.recipient != null && item.recipient!.isNotEmpty) {
        final existingIdx = dynamicClaims.indexWhere((c) => c.id == item.id);
        if (existingIdx == -1) {
          final isDone = item.status == DonationStatus.completed ||
              !item.isActive;
          dynamicClaims.add(
            _IncomingClaim(
              id: item.id,
              listingTitle: item.title,
              claimantName: item.recipient ?? 'Verified NGO Partner',
              claimantType: item.listingType == ListingType.discountedSale
                  ? 'Customer'
                  : 'NGO',
              claimantPhone: item.recipientPhone ?? '',
              quantity: item.quantity,
              quantityUnit: item.quantityUnit,
              category: item.category,
              verificationCode: item.qrCode ??
                  'CLM-${item.id.hashCode.abs() % 9000 + 1000}',
              amountPaid: item.discountedPrice,
              claimedAt: DateTime.now().subtract(const Duration(minutes: 15)),
              pickupWindowMinutes: 45,
              pickupNotes: 'Claimed surplus meal pickup.',
              status: isDone ? DonorClaimStatus.completed : DonorClaimStatus
                  .awaitingPickup,
            ),
          );
        }
      }
    }

    setState(() {
      _claims = dynamicClaims;
    });
  }

  List<_IncomingClaim> get _filteredClaims {
    return _claims.where((claim) {
      // ── Filter tab ──────────────────────────────────────────────────
      if (_selectedFilter == _ClaimSource.ngo &&
          (!claim.isNgo || !claim.isActive)) {
        return false;
      }
      if (_selectedFilter == _ClaimSource.customer &&
          (claim.isNgo || !claim.isActive)) {
        return false;
      }
      if (_selectedFilter == _ClaimSource.completed && claim.isActive) {
        return false;
      }

      // ── Text search ─────────────────────────────────────────────────
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return claim.listingTitle.toLowerCase().contains(q) ||
            claim.claimantName.toLowerCase().contains(q) ||
            claim.verificationCode.toLowerCase().contains(q) ||
            claim.claimantPhone.contains(q) ||
            claim.claimantType.toLowerCase().contains(q);
      }

      return true;
    }).toList();
  }

  // void _verifyAndHandover(_IncomingClaim claim) {
  //   final codeController = TextEditingController(text: claim.verificationCode);
  //
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: const Row(
  //         children: [
  //           Icon(Icons.verified_outlined, color: AppColors.primaryEmerald),
  //           SizedBox(width: 8),
  //           Text('Verify & Hand Over', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Handing over "${claim.listingTitle}" to ${claim.claimantName}.',
  //             style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
  //           ),
  //           const SizedBox(height: 14),
  //           Text(
  //             'Verification Code (Expected: ${claim.verificationCode}):',
  //             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
  //           ),
  //           const SizedBox(height: 8),
  //           TextField(
  //             controller: codeController,
  //             textCapitalization: TextCapitalization.characters,
  //             decoration: InputDecoration(
  //               hintText: 'Enter code e.g. ${claim.verificationCode}',
  //               hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
  //               filled: true,
  //               fillColor: const Color(0xFFF3F4F6),
  //               contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //                 borderSide: BorderSide.none,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(ctx).pop(),
  //           child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.primaryEmerald,
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //           ),
  //           onPressed: () async {
  //             Navigator.of(ctx).pop();
  //             final auth = context.read<AuthProvider>();
  //             final token = auth.currentUser?.token;
  //             final code = codeController.text.trim();
  //
  //             if (token != null && token.isNotEmpty) {
  //               final listingFlow = context.read<ListingFlowProvider>();
  //               await listingFlow.verifyPickupCode(
  //                 token: token,
  //                 manualCode: code,
  //                 qrCode: code,
  //               );
  //             }
  //
  //             setState(() {
  //               claim.status = DonorClaimStatus.completed;
  //             });
  //
  //             if (mounted) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text(
  //                     'Handover verified! "${claim.listingTitle}" marked as collected by ${claim.claimantName}.',
  //                   ),
  //                   backgroundColor: AppColors.success,
  //                   behavior: SnackBarBehavior.floating,
  //                 ),
  //               );
  //             }
  //           },
  //           child: const Text('Confirm Handover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _verifyAndHandover(_IncomingClaim claim) {
    final codeController = TextEditingController(text: claim.verificationCode);

    showDialog(
      context: context,
      builder: (ctx) =>
          StatefulBuilder(
            // StatefulBuilder lets the dialog rebuild itself (e.g. to reflect the
            // scanned code) without needing to convert this whole method into a
            // separate StatefulWidget.
            builder: (ctx, setDialogState) =>
                AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.verified_outlined,
                          color: AppColors.primaryEmerald),
                      SizedBox(width: 8),
                      Text('Verify & Hand Over', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Handing over "${claim.listingTitle}" to ${claim
                            .claimantName}.',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Verification Code (Expected: ${claim
                            .verificationCode}):',
                        style: const TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Enter code e.g. ${claim.verificationCode}',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner_rounded,
                                color: AppColors.primaryEmerald),
                            tooltip: 'Scan QR code',
                            onPressed: () async {
                              // Close the keyboard first so it doesn't fight with the
                              // camera view opening on top of the dialog.
                              FocusScope.of(ctx).unfocus();

                              final scanned = await Navigator.of(ctx).push<
                                  String>(
                                MaterialPageRoute(
                                  builder: (_) => const _QrScanScreen(),
                                  fullscreenDialog: true,
                                ),
                              );

                              if (scanned != null && scanned.isNotEmpty) {
                                codeController.text = scanned;
                                // Move the cursor to the end so it doesn't sit mid-text.
                                codeController.selection = TextSelection
                                    .fromPosition(
                                  TextPosition(
                                      offset: codeController.text.length),
                                );
                                setDialogState(() {}); // refresh the dialog to show the new value
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final auth = context.read<AuthProvider>();
                        final token = auth.currentUser?.token;
                        final code = codeController.text.trim();

                        if (token != null && token.isNotEmpty) {
                          final listingFlow = context.read<
                              ListingFlowProvider>();
                          await listingFlow.verifyPickupCode(
                            token: token,
                            manualCode: code,
                            qrCode: code,
                          );
                        }

                        setState(() {
                          claim.status = DonorClaimStatus.completed;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Handover verified! "${claim
                                    .listingTitle}" marked as collected by ${claim
                                    .claimantName}.',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Confirm Handover', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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

                // ── Search bar ─────────────────────────────────────────
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by food, claimant, or code…',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
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

                // ── Filter chips ───────────────────────────────────────
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
          Expanded(
            child: claims.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.receipt_long_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'No results for "$_searchQuery"'
                          : 'No Claims or Pickups Yet',
                      description: _searchQuery.isNotEmpty
                          ? 'Try different keywords — food title, claimant name, or verification code.'
                          : 'When verified NGOs claim your surplus donations or customers reserve flash sales, their pickup details will show up here.',
                      buttonText: _searchQuery.isNotEmpty
                          ? 'Clear Search'
                          : 'Post Food Listing',
                      buttonIcon: _searchQuery.isNotEmpty
                          ? Icons.clear
                          : Icons.add,
                      onButtonPressed: () {
                        if (_searchQuery.isNotEmpty) {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddDonationScreen(),
                            ),
                          );
                        }
                      },
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

  /// Minimal full-screen QR scanner. Pops with the decoded string as soon as
  /// the first valid code is detected.
class _QrScanScreen extends StatefulWidget {
  const _QrScanScreen();

  @override
  State<_QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<_QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false; // guards against firing multiple times per scan burst

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Handover QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller, // Listen to the controller notifier directly
              builder: (context, state, child) {
                // Read torchState safely from the emitted state snapshot
                final isTorchOn = state.torchState == TorchState.on;
                return Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Simple scan-frame overlay so it's clear where to aim the camera.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryEmerald, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}