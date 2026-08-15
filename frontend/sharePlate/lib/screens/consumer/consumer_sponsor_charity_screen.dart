import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/shared/empty_state_widget.dart';

class ConsumerSponsorCharityScreen extends StatefulWidget {
  const ConsumerSponsorCharityScreen({super.key});

  @override
  State<ConsumerSponsorCharityScreen> createState() =>
      _ConsumerSponsorCharityScreenState();
}

class _ConsumerSponsorCharityScreenState
    extends State<ConsumerSponsorCharityScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDonations();
    });
  }

  Future<void> _fetchDonations() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final token = auth.currentUser?.token;

    await context.read<DonationProvider>().fetchDonations(
      token: token,
    );
  }

  Future<void> _refresh() async {
    await _fetchDonations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DonationItem> _getAvailableDonations(
      DonationProvider provider,
      ) {
    final donations = provider.activeDonations.toList();

    if (_searchQuery.trim().isEmpty) {
      return donations;
    }

    final query = _searchQuery.trim().toLowerCase();

    return donations.where((donation) {
      final title =
      donation.title.toLowerCase();

      final donor =
      (donation.donorBusinessName ?? '')
          .toLowerCase();

      final address =
      donation.pickupAddress.toLowerCase();

      final category =
      donation.category.label.toLowerCase();

      return title.contains(query) ||
          donor.contains(query) ||
          address.contains(query) ||
          category.contains(query);
    }).toList();
  }

  void _showDonationDetails(
      DonationItem donation,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DonationDetailsSheet(
          donation: donation,
          onReserve: () {
            Navigator.of(context).pop();

            _showReserveMessage(donation);
          },
        );
      },
    );
  }

  void _showReserveMessage(
      DonationItem donation,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Open the reservation flow for "${donation.title}".',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider =
    context.watch<DonationProvider>();

    final donations =
    _getAvailableDonations(
      donationProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                12,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Donor Food Listings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            AppColors.primaryEmerald,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Available Food',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                            FontWeight.w900,
                            color:
                            AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration:
                    BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons
                              .restaurant_rounded,
                          size: 17,
                          color: AppColors
                              .primaryEmerald,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${donations.length}',
                          style:
                          const TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.bold,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // SEARCH
            // --------------------------------------------------
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                6,
                20,
                10,
              ),
              child: Container(
                decoration:
                BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: TextField(
                  controller:
                  _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery =
                          value.trim();
                    });
                  },
                  decoration:
                  InputDecoration(
                    hintText:
                    'Search food, donor, category or locality...',
                    hintStyle:
                    const TextStyle(
                      fontSize: 13,
                      color: AppColors
                          .textSecondary,
                    ),
                    prefixIcon:
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors
                          .textSecondary,
                      size: 20,
                    ),
                    suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                      icon:
                      const Icon(
                        Icons.clear,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchQuery =
                          '';
                        });
                      },
                    )
                        : null,
                    border:
                    InputBorder.none,
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // SECTION HEADER
            // --------------------------------------------------
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                10,
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
                children: [
                  const Text(
                    'Available Donations',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight:
                      FontWeight.bold,
                      color: AppColors
                          .textPrimary,
                    ),
                  ),
                  Text(
                    '${donations.length} listed',
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color: AppColors
                          .textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // DONATION LIST
            // --------------------------------------------------
            Expanded(
              child:
              donationProvider.isLoading &&
                  donations.isEmpty
                  ? const Center(
                child:
                CircularProgressIndicator(
                  color: AppColors
                      .primaryEmerald,
                ),
              )
                  : donations.isEmpty
                  ? Center(
                child:
                donationProvider
                    .errorMessage !=
                    null
                    ? EmptyStateWidget(
                  icon: Icons
                      .error_outline_rounded,
                  title:
                  'Couldn\'t Load Donations',
                  description:
                  donationProvider
                      .errorMessage!,
                  buttonText:
                  'Try Again',
                  buttonIcon:
                  Icons
                      .refresh_rounded,
                  onButtonPressed:
                  _refresh,
                )
                    : EmptyStateWidget(
                  icon: Icons
                      .restaurant_outlined,
                  title:
                  'No Food Available',
                  description:
                  'There are currently no active food donations available. Check back when donors post new food.',
                  buttonText:
                  'Refresh',
                  buttonIcon:
                  Icons
                      .refresh_rounded,
                  onButtonPressed:
                  _refresh,
                ),
              )
                  : RefreshIndicator(
                color: AppColors
                    .primaryEmerald,
                onRefresh:
                _refresh,
                child:
                ListView.separated(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    0,
                    20,
                    24,
                  ),
                  itemCount:
                  donations.length,
                  separatorBuilder:
                      (_, __) =>
                  const SizedBox(
                    height: 12,
                  ),
                  itemBuilder:
                      (context,
                      index) {
                    final donation =
                    donations[
                    index];

                    return _DonationCard(
                      donation:
                      donation,
                      onTap: () =>
                          _showDonationDetails(
                            donation,
                          ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DONATION CARD
// ============================================================

class _DonationCard extends StatelessWidget {
  const _DonationCard({
    required this.donation,
    required this.onTap,
  });

  final DonationItem donation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discountedPrice =
        donation.discountedPrice;

    final originalPrice =
        donation.originalPrice;

    final hasDiscount =
        discountedPrice != null &&
            originalPrice != null &&
            discountedPrice < originalPrice;

    final discountPercent =
    hasDiscount
        ? ((originalPrice! -
        discountedPrice!) /
        originalPrice *
        100)
        .round()
        : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(16),
        child: Container(
          decoration:
          BoxDecoration(
            color: AppColors.surface,
            borderRadius:
            BorderRadius.circular(16),
            border: Border.all(
              color: hasDiscount
                  ? const Color(
                0xFFFFB74D,
              )
                  : AppColors.border,
              width: hasDiscount
                  ? 1.2
                  : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withAlpha(8),
                blurRadius: 8,
                offset:
                const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
            const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // --------------------------------------------
                // TOP ROW
                // --------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        donation.donorBusinessName
                            ?.isNotEmpty ==
                            true
                            ? donation
                            .donorBusinessName!
                            : 'Local Food Business',
                        style:
                        const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600,
                          color: AppColors
                              .textSecondary,
                        ),
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                      ),
                    ),

                    if (hasDiscount)
                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFFFF3E0,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            6,
                          ),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style:
                          const TextStyle(
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            Color(
                              0xFFE65100,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // --------------------------------------------
                // TITLE
                // --------------------------------------------
                Text(
                  donation.title,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                    color: AppColors
                        .textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                // --------------------------------------------
                // CATEGORY + QUANTITY
                // --------------------------------------------
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons
                          .category_outlined,
                      text: donation
                          .category.label,
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    _InfoChip(
                      icon: Icons
                          .inventory_2_outlined,
                      text:
                      '${donation.quantity} ${donation.quantityUnit}',
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // --------------------------------------------
                // DESCRIPTION
                // --------------------------------------------
                if (donation.description !=
                    null &&
                    donation.description!
                        .trim()
                        .isNotEmpty) ...[
                  Text(
                    donation.description!,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 12.5,
                      color: AppColors
                          .textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],

                // --------------------------------------------
                // PICKUP LOCATION
                // --------------------------------------------
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Icon(
                      Icons
                          .location_on_outlined,
                      size: 16,
                      color: AppColors
                          .textSecondary,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Expanded(
                      child: Text(
                        donation
                            .pickupAddress,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 12,
                          color: AppColors
                              .textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                // --------------------------------------------
                // PICKUP WINDOW
                // --------------------------------------------
                Row(
                  children: [
                    const Icon(
                      Icons
                          .access_time_rounded,
                      size: 16,
                      color: AppColors
                          .textSecondary,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      donation.pickupWindow,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color: AppColors
                            .textSecondary,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                const Divider(
                  height: 1,
                  color:
                  AppColors.border,
                ),

                const SizedBox(
                  height: 12,
                ),

                // --------------------------------------------
                // PRICE + BUTTON
                // --------------------------------------------
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          if (hasDiscount)
                            Row(
                              children: [
                                Text(
                                  'Rs. ${discountedPrice!.toInt()}',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    19,
                                    fontWeight:
                                    FontWeight
                                        .w900,
                                    color: AppColors
                                        .primaryEmerald,
                                  ),
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  'Rs. ${originalPrice!.toInt()}',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    12,
                                    decoration:
                                    TextDecoration
                                        .lineThrough,
                                    color: AppColors
                                        .textSecondary,
                                  ),
                                ),
                              ],
                            )
                          else if (discountedPrice !=
                              null)
                            Text(
                              'Rs. ${discountedPrice.toInt()}',
                              style:
                              const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                FontWeight
                                    .w900,
                                color: AppColors
                                    .primaryEmerald,
                              ),
                            )
                          else
                            const Text(
                              'FREE',
                              style:
                              TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight
                                    .w900,
                                color: AppColors
                                    .primaryEmerald,
                              ),
                            ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            hasDiscount
                                ? 'Flash sale price'
                                : 'Donation',
                            style:
                            const TextStyle(
                              fontSize: 10.5,
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ElevatedButton(
                      onPressed: onTap,
                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        AppColors
                            .primaryEmerald,
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 17,
                          vertical: 11,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                        ),
                      ),
                      child:
                      const Text(
                        'View & Reserve',
                        style:
                        TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// INFO CHIP
// ============================================================

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFF1F5F9),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color:
            AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style:
            const TextStyle(
              fontSize: 10.5,
              fontWeight:
              FontWeight.w600,
              color: AppColors
                  .textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DONATION DETAILS SHEET
// ============================================================

class _DonationDetailsSheet
    extends StatelessWidget {
  const _DonationDetailsSheet({
    required this.donation,
    required this.onReserve,
  });

  final DonationItem donation;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final discountedPrice =
        donation.discountedPrice;

    final originalPrice =
        donation.originalPrice;

    final hasDiscount =
        discountedPrice != null &&
            originalPrice != null &&
            discountedPrice <
                originalPrice;

    final discountPercent =
    hasDiscount
        ? ((originalPrice! -
        discountedPrice!) /
        originalPrice *
        100)
        .round()
        : 0;

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20,
      ),
      decoration:
      const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
        BorderRadius.vertical(
          top:
          Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration:
                BoxDecoration(
                  color:
                  AppColors.border,
                  borderRadius:
                  BorderRadius.circular(
                    3,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    donation.title,
                    style:
                    const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                      color: AppColors
                          .textPrimary,
                    ),
                  ),
                ),
                if (hasDiscount)
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFFFF3E0,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        7,
                      ),
                    ),
                    child: Text(
                      '$discountPercent% OFF',
                      style:
                      const TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(
                          0xFFE65100,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              donation.donorBusinessName
                  ?.isNotEmpty ==
                  true
                  ? donation
                  .donorBusinessName!
                  : 'Local Food Business',
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color: AppColors
                    .primaryEmerald,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (donation.description !=
                null &&
                donation.description!
                    .trim()
                    .isNotEmpty)
              Text(
                donation.description!,
                style:
                const TextStyle(
                  fontSize: 13,
                  color: AppColors
                      .textSecondary,
                  height: 1.4,
                ),
              ),

            const SizedBox(
              height: 16,
            ),

            _DetailRow(
              icon: Icons
                  .inventory_2_outlined,
              label: 'Quantity',
              value:
              '${donation.quantity} ${donation.quantityUnit}',
            ),

            _DetailRow(
              icon: Icons
                  .category_outlined,
              label: 'Category',
              value:
              donation.category.label,
            ),

            _DetailRow(
              icon: Icons
                  .location_on_outlined,
              label: 'Pickup',
              value:
              donation.pickupAddress,
            ),

            _DetailRow(
              icon: Icons
                  .access_time_rounded,
              label: 'Pickup Window',
              value:
              donation.pickupWindow,
            ),

            const SizedBox(
              height: 12,
            ),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFF8FAFC,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Price',
                    style:
                    TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color: AppColors
                          .textSecondary,
                    ),
                  ),
                  const Spacer(),

                  if (hasDiscount) ...[
                    Text(
                      'Rs. ${originalPrice!.toInt()}',
                      style:
                      const TextStyle(
                        fontSize: 12,
                        decoration:
                        TextDecoration
                            .lineThrough,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                  ],

                  Text(
                    discountedPrice !=
                        null
                        ? 'Rs. ${discountedPrice.toInt()}'
                        : 'FREE',
                    style:
                    const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.w900,
                      color: AppColors
                          .primaryEmerald,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,
              child:
              ElevatedButton(
                onPressed:
                onReserve,
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  AppColors
                      .primaryEmerald,
                  foregroundColor:
                  Colors.white,
                  elevation: 0,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 14,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child:
                const Text(
                  'Reserve Food',
                  style:
                  TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow
    extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color:
            AppColors.textSecondary,
          ),
          const SizedBox(
            width: 8,
          ),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color: AppColors
                    .textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color: AppColors
                    .textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}