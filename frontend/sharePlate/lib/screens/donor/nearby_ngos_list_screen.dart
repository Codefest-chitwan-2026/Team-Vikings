import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/nearby_ngo_model.dart';
import '../../providers/donation_provider.dart';
import 'add_donation_screen.dart';
import 'ngo_detail_screen.dart';

enum NgoListFilter { all, orphanage, communityKitchen, elderlyHome, highUrgency, withinTwoKm }

class NearbyNgosListScreen extends StatefulWidget {
  const NearbyNgosListScreen({super.key});

  @override
  State<NearbyNgosListScreen> createState() => _NearbyNgosListScreenState();
}

class _NearbyNgosListScreenState extends State<NearbyNgosListScreen> {
  final TextEditingController _searchController = TextEditingController();
  NgoListFilter _selectedFilter = NgoListFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NearbyNgo> _filterNgos(List<NearbyNgo> ngos) {
    final query = _searchController.text.trim().toLowerCase();

    return ngos.where((ngo) {
      final matchesQuery = query.isEmpty ||
          ngo.name.toLowerCase().contains(query) ||
          ngo.address.toLowerCase().contains(query) ||
          ngo.category.toLowerCase().contains(query) ||
          ngo.description.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      switch (_selectedFilter) {
        case NgoListFilter.all:
          return true;
        case NgoListFilter.orphanage:
          return ngo.category.toLowerCase().contains('orphan');
        case NgoListFilter.communityKitchen:
          return ngo.category.toLowerCase().contains('kitchen') || ngo.category.toLowerCase().contains('community');
        case NgoListFilter.elderlyHome:
          return ngo.category.toLowerCase().contains('elder') || ngo.category.toLowerCase().contains('senior');
        case NgoListFilter.highUrgency:
          return ngo.urgencyLevel == 'High';
        case NgoListFilter.withinTwoKm:
          return ngo.distanceKm <= 2.0;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final filteredNgos = _filterNgos(donationProvider.nearbyNgos);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'NGOs Near You',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search NGOs by name, cause or area...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Horizontal Filter Chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _filterChip('All NGOs', NgoListFilter.all),
                  const SizedBox(width: 8),
                  _filterChip('High Urgency', NgoListFilter.highUrgency),
                  const SizedBox(width: 8),
                  _filterChip('Within 2 km', NgoListFilter.withinTwoKm),
                  const SizedBox(width: 8),
                  _filterChip('Orphanages', NgoListFilter.orphanage),
                  const SizedBox(width: 8),
                  _filterChip('Community Kitchens', NgoListFilter.communityKitchen),
                  const SizedBox(width: 8),
                  _filterChip('Elderly Homes', NgoListFilter.elderlyHome),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Ngo Card List
            Expanded(
              child: filteredNgos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.apartment, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No organizations found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try clearing search or choosing another category.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedFilter = NgoListFilter.all;
                              });
                            },
                            child: const Text('Reset filters'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: filteredNgos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ngo = filteredNgos[index];
                        return _NgoListItemCard(
                          ngo: ngo,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                // builder: (_) => NgoDetailScreen(ngo: ngo),
                                builder: (_) => NgoDetailScreen(),

                              ),
                            );
                          },
                          onDonateTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddDonationScreen(
                                  prefilledAddress: ngo.address,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, NgoListFilter filter) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primaryEmerald,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primaryEmerald : AppColors.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      showCheckmark: false,
    );
  }
}

class _NgoListItemCard extends StatelessWidget {
  final NearbyNgo ngo;
  final VoidCallback onTap;
  final VoidCallback onDonateTap;

  const _NgoListItemCard({
    required this.ngo,
    required this.onTap,
    required this.onDonateTap,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
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
                      gradient: LinearGradient(
                        colors: ngo.bannerGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ngo.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (ngo.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: Color(0xFF1976D2)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${ngo.category} · ${ngo.distanceLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryEmerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ngo.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_dining_outlined, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ngo.currentNeeds.isNotEmpty ? ngo.currentNeeds.first : 'Looking for surplus food donations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ngo.totalMealsReceived}+ meals received',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onDonateTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Donate Food', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
