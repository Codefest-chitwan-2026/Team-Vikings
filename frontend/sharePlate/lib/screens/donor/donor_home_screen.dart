import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/contribution_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/donor/donor_bottom_navigation.dart';
import 'contribution_detail_screen.dart';
import 'contribution_list_screen.dart';
import 'donor_claims_management_screen.dart';
import 'donor_notifications_screen.dart';
import 'donor_profile_screen.dart';
import 'my_donations_screen.dart';
import 'nearby_ngos_list_screen.dart';
import 'ngo_detail_screen.dart';
import '../../models/nearby_ngo_model.dart' as ngo_model;

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final token = auth.currentUser?.token;
      if (token != null && token.isNotEmpty) {
        final dp = context.read<DonationProvider>();
        dp.fetchDonations(token: token);
        dp.fetchContributions(token: token);
        dp.fetchNearbyNgos();
        dp.fetchClaims(token: token);
      }
    });
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTab = index);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DonorNotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _DonorHomeTab(
            onNotificationsTap: _openNotifications,
            onViewAllContributions: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ContributionListScreen()),
              );
            },
            onViewNearbyNgos: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NearbyNgosListScreen()),
              );
            },
          ),
          const MyDonationsScreen(),
          const DonorClaimsManagementScreen(),
          const DonorProfileScreen(),
        ],
      ),
      bottomNavigationBar: DonorBottomNavigation(
        currentIndex: _selectedTab,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _DonorHomeTab extends StatelessWidget {
  const _DonorHomeTab({
    required this.onNotificationsTap,
    required this.onViewAllContributions,
    required this.onViewNearbyNgos,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onViewAllContributions;
  final VoidCallback onViewNearbyNgos;

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final contributions = donationProvider.contributions;
    final ngos = donationProvider.nearbyNgos;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentHeight = constraints.maxHeight * 0.82;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _DonorHomeHeader(onNotificationsTap: onNotificationsTap),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: contentHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _CampaignCard(
                          onViewMore: onViewNearbyNgos,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionHeader(
                        title: 'Recent Contribution',
                        actionLabel: 'View all',
                        onActionTap: onViewAllContributions,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: contributions.isNotEmpty
                            ? _ContributionCard(
                                contribution: contributions.first,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ContributionDetailScreen(
                                        contribution: contributions.first,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.volunteer_activism_rounded,
                                        color: AppColors.primaryEmerald,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'No contributions yet',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Post surplus food to start tracking impact.',
                                            style: TextStyle(
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
                      ),
                      const SizedBox(height: 14),
                      _SectionHeader(
                        title: 'NGOs Near You',
                        actionLabel: 'See more',
                        onActionTap: onViewNearbyNgos,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: ngos.isNotEmpty
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _NearbyNgoCard(
                                      ngo: ngos[0],
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => NgoDetailScreen(ngo: ngos[0]),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ngos.length > 1
                                        ? _NearbyNgoCard(
                                            ngo: ngos[1],
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => NgoDetailScreen(ngo: ngos[1]),
                                                ),
                                              );
                                            },
                                          )
                                        : _ExploreMoreNgosCard(onTap: onViewNearbyNgos),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: AppColors.primaryEmerald),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Discover verified NGOs operating in Chitwan.',
                                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: onViewNearbyNgos,
                                      child: const Text('Browse'),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ExploreMoreNgosCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ExploreMoreNgosCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_outlined, color: AppColors.primaryEmerald, size: 28),
                SizedBox(height: 6),
                Text(
                  'Explore More',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonorHomeHeader extends StatelessWidget {
  const _DonorHomeHeader({required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Welcome back',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Food Donor Dashboard',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onNotificationsTap,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: AppColors.charcoal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.onViewMore});

  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF197236), Color(0xFF104C25)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            "Support campaign cost for\nchildren's school meals",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 19,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onViewMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Explore NGOs →',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1677D2),
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 28),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final ContributionItem contribution;
  final VoidCallback onTap;

  const _ContributionCard({
    required this.contribution,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: contribution.bannerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      contribution.recipientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contribution.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(label: contribution.statusLabel),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    contribution.dateAgo,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F6E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NearbyNgoCard extends StatelessWidget {
  const _NearbyNgoCard({required this.ngo, required this.onTap});

  final ngo_model.NearbyNgo ngo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ngo.bannerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.apartment, color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ngo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                ngo.distanceLabel,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
