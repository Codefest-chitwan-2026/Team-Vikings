import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/nearby_ngo_model.dart';
import 'add_donation_screen.dart';

class NgoDetailScreen extends StatelessWidget {
  final NearbyNgo ngo;

  const NgoDetailScreen({super.key, required this.ngo});

  void _onDonateToNgo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddDonationScreen(
          prefilledAddress: ngo.address,
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(ngo.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Person: ${ngo.contactPerson}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Phone: ${ngo.phoneNumber}'),
            const SizedBox(height: 4),
            Text('Email: ${ngo.email}'),
            const SizedBox(height: 8),
            Text('Address: ${ngo.address}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${ngo.phoneNumber}...')),
              );
            },
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Banner App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: ngo.bannerGradient.first,
            leading: Material(
              color: Colors.black26,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing ${ngo.name} profile...')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ngo.bannerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Icon(Icons.apartment, color: ngo.bannerGradient.first, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ngo.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (ngo.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: Colors.white, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ngo.category} · ${ngo.distanceLabel}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Government & SWC Registered · PAN: ${ngo.panNumber}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Impact Stat Cards
                  Row(
                    children: [
                      Expanded(
                        child: _NgoStatCard(
                          label: 'Meals Received',
                          value: '${ngo.totalMealsReceived}+',
                          icon: Icons.volunteer_activism,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NgoStatCard(
                          label: 'People Supported',
                          value: '${ngo.peopleSupported}',
                          icon: Icons.group,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NgoStatCard(
                          label: 'Urgency',
                          value: ngo.urgencyLevel,
                          icon: Icons.local_fire_department,
                          color: ngo.urgencyLevel == 'High' ? AppColors.error : AppColors.warning,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Current Food Needs
                  _CardSection(
                    title: 'Current Food Needs',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final need in ngo.currentNeeds) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_box_outlined, size: 16, color: AppColors.primaryEmerald),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    need,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About Section
                  _CardSection(
                    title: 'About the Organization',
                    child: Text(
                      ngo.description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact & Location Card
                  _CardSection(
                    title: 'Contact & Location',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Representative',
                          value: ngo.contactPerson,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: ngo.address,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: ngo.phoneNumber,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: ngo.email,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showContactDialog(context),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Contact NGO'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _onDonateToNgo(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Donate Food'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryEmerald,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NgoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NgoStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
