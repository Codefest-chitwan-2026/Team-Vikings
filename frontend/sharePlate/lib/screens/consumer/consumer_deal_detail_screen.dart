import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/consumer_order_model.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/login_screen/primary_button.dart';

class ConsumerDealDetailScreen extends StatefulWidget {
  const ConsumerDealDetailScreen({super.key, required this.deal});

  final DonationItem deal;

  @override
  State<ConsumerDealDetailScreen> createState() => _ConsumerDealDetailScreenState();
}

class _ConsumerDealDetailScreenState extends State<ConsumerDealDetailScreen> {
  bool _isReserving = false;

  Future<void> _reserveDeal() async {
    setState(() => _isReserving = true);
    final auth = context.read<AuthProvider>();
    final donationProvider = context.read<DonationProvider>();
    final orderProvider = context.read<OrderProvider>();
    final token = auth.currentUser?.token;

    String qrCode = 'DEAL-${widget.deal.id}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    final res = await donationProvider.reserveFlashSaleOnApi(
      token: token,
      donationId: widget.deal.id,
    );

    if (!mounted) return;
    setState(() => _isReserving = false);

    if (res != null) {
      if (res['reservation']?['pickup_ticket']?['qr_code'] != null) {
        qrCode = res['reservation']['pickup_ticket']['qr_code'].toString();
      } else if (res['order_code'] != null) {
        qrCode = res['order_code'].toString();
      }

      final newOrder = ConsumerOrderModel(
        id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
        orderCode: qrCode,
        title: widget.deal.title,
        storeName: widget.deal.donorBusinessName ?? 'Local Food Store',
        storePhone: widget.deal.recipientPhone ?? '',
        pickupAddress: widget.deal.pickupAddress,
        originalPrice: widget.deal.originalPrice ?? 300,
        discountedPrice: widget.deal.discountedPrice ?? 150,
        category: widget.deal.category,
        orderTime: DateTime.now(),
        pickupWindowMinutes: 45,
        status: ConsumerOrderStatus.readyForPickup,
        qrCode: qrCode,
        donationId: widget.deal.id,
      );
      orderProvider.addOrder(newOrder);

      _showPickupTicketModal(qrCode);
    } else {
      final msg = donationProvider.errorMessage ?? 'Unable to reserve deal. It may already be claimed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPickupTicketModal(String qrCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryEmerald, size: 54),
              const SizedBox(height: 10),
              const Text(
                'Deal Reserved Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Show this pickup ticket code to the store staff at collection.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 90, color: AppColors.charcoal),
                    const SizedBox(height: 8),
                    Text(
                      'CODE: $qrCode',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount to pay at pickup:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          'Rs ${(widget.deal.discountedPrice ?? 150).toInt()}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Done',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Deal Details',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.cardLightBg,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                deal.category == FoodCategory.veg ? '🥗' : (deal.category == FoodCategory.nonVeg ? '🍗' : '🥐'),
                style: const TextStyle(fontSize: 56),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              deal.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (deal.originalPrice != null)
                  Text(
                    'Rs ${deal.originalPrice!.toInt()}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                if (deal.originalPrice != null) const SizedBox(width: 8),
                Text(
                  'Rs ${(deal.discountedPrice ?? 150).toInt()}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              deal.description ?? 'Fresh and hygienic discounted food prepared today.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pickup Location & Instructions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primaryEmerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.pickupAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pickup window: ${deal.pickupWindow}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Reserve this Deal for Rs ${(deal.discountedPrice ?? 150).toInt()}',
              isLoading: _isReserving,
              onPressed: _reserveDeal,
            ),
          ],
        ),
      ),
    );
  }
}
