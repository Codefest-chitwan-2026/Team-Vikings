import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/donation_provider.dart';
import '../../widgets/donor/add_donation/photo_upload_area.dart';
import 'add_donation_screen.dart';
import 'donation_receipt_screen.dart';
import 'track_donation_screen.dart';

class DonationDetailScreen extends StatelessWidget {
  final DonationItem donation;

  const DonationDetailScreen({super.key, required this.donation});

  void _onEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddDonationScreen(donationToEdit: donation),
      ),
    );
  }

  void _onRepeat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddDonationScreen(
          prefilledTitle: donation.title.split('·').first.trim(),
          prefilledQuantity: donation.quantity.toString(),
          prefilledCategory: donation.category,
          prefilledServes: donation.servesApprox,
          prefilledAddress: donation.pickupAddress,
        ),
      ),
    );
  }

  void _onReceipt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DonationReceiptScreen(donation: donation),
      ),
    );
  }

  void _onTrack(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackDonationScreen(donation: donation),
      ),
    );
  }

  void _onCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Cancel Donation?'),
        content: const Text(
          'Are you sure you want to cancel this food listing? Volunteers or recipients will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Listing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<DonationProvider>().cancelDonation(donation.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation cancelled.'),
                  backgroundColor: AppColors.error,
                ),
              );
              Navigator.of(context).maybePop();
            },
            child: const Text('Cancel Listing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = donation.imagePath != null && donation.imagePath!.isNotEmpty;
    final isPreset = hasImage && donation.imagePath!.startsWith('preset:');
    final isLocalFile = hasImage && !isPreset && !kIsWeb && File(donation.imagePath!).existsSync();

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
          'Donation Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (donation.status == DonationStatus.completed)
            IconButton(
              icon: const Icon(Icons.receipt_long, color: AppColors.primaryEmerald),
              tooltip: 'Receipt',
              onPressed: () => _onReceipt(context),
            ),
          if (donation.status == DonationStatus.awaitingClaim)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryEmerald),
              tooltip: 'Edit',
              onPressed: () => _onEdit(context),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Top Image or Banner
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isPreset
                    ? _presetBanner(donation.imagePath!)
                    : isLocalFile
                        ? Image.file(
                            File(donation.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _fallbackBanner(),
                          )
                        : _fallbackBanner(),
              ),
            ),

            const SizedBox(height: 20),

            // Title & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posted ${donation.postedAgo}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: donation.status),
              ],
            ),

            const SizedBox(height: 20),

            // Specs Row
            Row(
              children: [
                Expanded(
                  child: _SpecTile(
                    label: 'Category',
                    value: donation.categoryLabel,
                    icon: Icons.fastfood_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SpecTile(
                    label: 'Quantity',
                    value: '${donation.quantity} ${donation.quantityUnit}',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SpecTile(
                    label: 'Servings',
                    value: donation.servesApprox,
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pickup Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.primaryEmerald, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Address',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              donation.pickupAddress,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time, color: Color(0xFFE65100), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Window',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Ready within ${donation.pickupWindow}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (donation.recipient != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipient Organization',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.apartment, color: Color(0xFF1976D2), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donation.recipient!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (donation.recipientAddress != null)
                                Text(
                                  donation.recipientAddress!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Dynamic Action Buttons
            if (donation.status == DonationStatus.awaitingClaim) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onEdit(context),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Listing'),
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Listing boosted! Notifying nearby NGOs on high priority.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.rocket_launch, size: 18),
                      label: const Text('Boost Post'),
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
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => _onCancel(context),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                  label: const Text('Cancel this donation', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ] else if (donation.status == DonationStatus.ngoEnRoute) ...[
              ElevatedButton.icon(
                onPressed: () => _onTrack(context),
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: const Text('Track NGO Live Pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => _onCancel(context),
                  icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                  label: const Text('Cancel pickup', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ] else if (donation.status == DonationStatus.completed) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onReceipt(context),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('View Receipt'),
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
                      onPressed: () => _onRepeat(context),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: const Text('Repeat Listing'),
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
          ],
        ),
      ),
    );
  }

  Widget _presetBanner(String presetId) {
    final preset = SampleFoodPreset.presets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => SampleFoodPreset.presets.first,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: preset.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(preset.icon, color: Colors.white, size: 54),
            const SizedBox(height: 10),
            Text(
              preset.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1EAA55), Color(0xFF0F6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.white, size: 48),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DonationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case DonationStatus.awaitingClaim:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        text = 'Awaiting Claim';
        break;
      case DonationStatus.ngoEnRoute:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        text = 'NGO En Route';
        break;
      case DonationStatus.completed:
        bg = const Color(0xFFE8F5E9);
        fg = AppColors.primary;
        text = 'Completed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SpecTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEmerald),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
