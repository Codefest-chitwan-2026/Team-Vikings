import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/contribution_model.dart';
import '../../models/donation_model.dart';
import '../../providers/donation_provider.dart';
import 'contribution_detail_screen.dart';

enum ContributionFilter { all, completed, inProgress, veg, nonVeg }

class ContributionListScreen extends StatefulWidget {
  const ContributionListScreen({super.key});

  @override
  State<ContributionListScreen> createState() => _ContributionListScreenState();
}

class _ContributionListScreenState extends State<ContributionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ContributionFilter _selectedFilter = ContributionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContributionItem> _filterContributions(List<ContributionItem> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.recipientName.toLowerCase().contains(query) ||
          item.pickupAddress.toLowerCase().contains(query) ||
          item.recipientAddress.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      switch (_selectedFilter) {
        case ContributionFilter.all:
          return true;
        case ContributionFilter.completed:
          return item.status == DonationStatus.completed;
        case ContributionFilter.inProgress:
          return item.status == DonationStatus.ngoEnRoute || item.status == DonationStatus.awaitingClaim;
        case ContributionFilter.veg:
          return item.category == FoodCategory.veg;
        case ContributionFilter.nonVeg:
          return item.category == FoodCategory.nonVeg || item.category == FoodCategory.mixed;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final filteredList = _filterContributions(donationProvider.contributions);

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
          'My Contributions',
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
            // Search Field
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
                    hintText: 'Search by NGO, food item or location...',
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
                  _filterChip('All', ContributionFilter.all),
                  const SizedBox(width: 8),
                  _filterChip('Completed', ContributionFilter.completed),
                  const SizedBox(width: 8),
                  _filterChip('In Progress', ContributionFilter.inProgress),
                  const SizedBox(width: 8),
                  _filterChip('Vegetarian', ContributionFilter.veg),
                  const SizedBox(width: 8),
                  _filterChip('Non-Veg / Mixed', ContributionFilter.nonVeg),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Contribution Cards List
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volunteer_activism_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No contributions found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try changing your search or active filter.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedFilter = ContributionFilter.all;
                              });
                            },
                            child: const Text('Reset filters'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return _ContributionListItem(
                          item: item,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContributionDetailScreen(contribution: item),
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

  Widget _filterChip(String label, ContributionFilter filter) {
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

class _ContributionListItem extends StatelessWidget {
  final ContributionItem item;
  final VoidCallback onTap;

  const _ContributionListItem({required this.item, required this.onTap});

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.bannerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.recipientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          item.dateAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4F6E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.plates} plates (${item.categoryLabel})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
