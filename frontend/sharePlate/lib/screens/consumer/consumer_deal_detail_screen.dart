import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../models/consumer_order_model.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donation_provider.dart';
import '../../providers/order_provider.dart';

class ConsumerDealDetailScreen extends StatefulWidget {
  const ConsumerDealDetailScreen({super.key, required this.deal});

  final DonationItem deal;

  @override
  State<ConsumerDealDetailScreen> createState() =>
      _ConsumerDealDetailScreenState();
}

class _ConsumerDealDetailScreenState extends State<ConsumerDealDetailScreen> {
  bool _isReserving = false;

  // ── Payment methods ────────────────────────────────────────────────────
  static const _paymentMethods = [
    _PaymentOption(
      id: 'eSewa',
      label: 'eSewa',
      subtitle: 'Mobile Wallet',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF60BB46),
    ),
    _PaymentOption(
      id: 'Khalti',
      label: 'Khalti',
      subtitle: 'Digital Wallet',
      icon: Icons.payment_rounded,
      color: Color(0xFF5C2D91),
    ),
    _PaymentOption(
      id: 'IME Pay',
      label: 'IME Pay',
      subtitle: 'Mobile Banking',
      icon: Icons.phone_android_rounded,
      color: Color(0xFFE53935),
    ),
  ];

  // ── Image URL helper ───────────────────────────────────────────────────
  static String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final rel = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.baseUrl}/$rel';
  }

  // ── Step 1: show payment picker sheet ─────────────────────────────────
  void _openPaymentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _PaymentPickerSheet(
        deal: widget.deal,
        methods: _paymentMethods,
        onConfirm: (selectedMethod) {
          Navigator.of(sheetCtx).pop();
          _doReserve(selectedMethod);
        },
      ),
    );
  }

  // ── Step 2: call API, show QR sheet, then pop back ─────────────────────
  Future<void> _doReserve(String paymentMethod) async {
    setState(() => _isReserving = true);

    final auth = context.read<AuthProvider>();
    final donationProvider = context.read<DonationProvider>();
    final orderProvider = context.read<OrderProvider>();
    final token = auth.currentUser?.token;

    // Optimistically generate a fallback code
    String qrCode =
        'DEAL-${widget.deal.id}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    final res = await donationProvider.reserveFlashSaleOnApi(
      token: token,
      donationId: widget.deal.id,
    );

    if (!mounted) return;
    setState(() => _isReserving = false);

    if (res != null) {
      // Extract QR from API response
      if (res['reservation']?['pickup_ticket']?['qr_code'] != null) {
        qrCode =
            res['reservation']['pickup_ticket']['qr_code'].toString();
      } else if (res['order_code'] != null) {
        qrCode = res['order_code'].toString();
      }

      // Save order locally
      final newOrder = ConsumerOrderModel(
        id: 'ord-${DateTime.now().millisecondsSinceEpoch}',
        orderCode: qrCode,
        title: widget.deal.title,
        storeName:
            widget.deal.donorBusinessName ?? 'Local Food Store',
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

      // Remove from flash sales list immediately
      donationProvider.removeFlashSale(widget.deal.id);

      // Show QR ticket — on Done, pop detail screen
      _showQrTicketSheet(qrCode, paymentMethod);
    } else {
      final msg = donationProvider.errorMessage ??
          'Unable to reserve deal. It may already be claimed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Step 3: QR ticket bottom sheet ─────────────────────────────────────
  void _showQrTicketSheet(String qrCode, String paymentMethod) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrTicketSheet(
        deal: widget.deal,
        qrCode: qrCode,
        paymentMethod: paymentMethod,
        onDone: () {
          Navigator.of(ctx).pop(); // close sheet
          Navigator.of(context).pop(); // pop detail screen → deals tab
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final imageUrl = _resolveImageUrl(deal.imagePath);
    final discountPct = (deal.originalPrice != null &&
            deal.discountedPrice != null &&
            deal.originalPrice! > 0)
        ? (((deal.originalPrice! - deal.discountedPrice!) /
                    deal.originalPrice!) *
                100)
            .round()
        : 50;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.charcoal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Deal Details',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Hero image / emoji ───────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _emojiPlaceholder(deal.category),
                      )
                    else
                      _emojiPlaceholder(deal.category),
                    // Discount badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$discountPct% OFF',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Title + price ────────────────────────────────────────
            Text(
              deal.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            if (deal.donorBusinessName != null &&
                deal.donorBusinessName!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    deal.donorBusinessName!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (deal.originalPrice != null) ...[
                  Text(
                    'Rs ${deal.originalPrice!.toInt()}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Rs ${(deal.discountedPrice ?? 150).toInt()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Info chips ───────────────────────────────────────────
            Row(
              children: [
                _infoChip(Icons.inventory_2_outlined,
                    '${deal.quantity} ${deal.quantityUnit}'),
                const SizedBox(width: 8),
                _infoChip(Icons.people_outline, deal.servesApprox),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            // ── Description ──────────────────────────────────────────
            const Text(
              'Description',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              deal.description ??
                  'Fresh and hygienic discounted food prepared today.',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 20),

            // ── Pickup ───────────────────────────────────────────────
            const Text(
              'Pickup Location',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
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
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.primaryEmerald),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.pickupAddress,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pickup window: ${deal.pickupWindow}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── Reserve button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isReserving ? null : _openPaymentPicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  disabledBackgroundColor:
                      AppColors.primaryEmerald.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isReserving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Reserve this Deal · Rs ${(deal.discountedPrice ?? 150).toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiPlaceholder(FoodCategory cat) {
    return Container(
      color: AppColors.cardLightBg,
      alignment: Alignment.center,
      child: Text(
        cat == FoodCategory.veg
            ? '🥗'
            : cat == FoodCategory.nonVeg
                ? '🍗'
                : '🥐',
        style: const TextStyle(fontSize: 64),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment option data class
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentOption {
  const _PaymentOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentPickerSheet extends StatefulWidget {
  const _PaymentPickerSheet({
    required this.deal,
    required this.methods,
    required this.onConfirm,
  });

  final DonationItem deal;
  final List<_PaymentOption> methods;
  final ValueChanged<String> onConfirm;

  @override
  State<_PaymentPickerSheet> createState() => _PaymentPickerSheetState();
}

class _PaymentPickerSheetState extends State<_PaymentPickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.methods.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final amount = (deal.discountedPrice ?? 150).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You will pay Rs $amount at the store after picking up.',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Order summary mini card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cardLightBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      deal.category == FoodCategory.veg
                          ? '🥗'
                          : deal.category == FoodCategory.nonVeg
                              ? '🍗'
                              : '🥐',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.title,
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
                          deal.donorBusinessName ?? deal.pickupAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (deal.originalPrice != null)
                        Text(
                          'Rs ${deal.originalPrice!.toInt()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        'Rs $amount',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Pay with',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Payment method cards
            ...widget.methods.map((m) {
              final isSelected = _selected == m.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = m.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? m.color.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? m.color : AppColors.border,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(m.icon, size: 20, color: m.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? m.color
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                m.subtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Radio dot
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? m.color : AppColors.border,
                              width: isSelected ? 5.5 : 1.5,
                            ),
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 6),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onConfirm(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm & Reserve · Rs $amount',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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

// ─────────────────────────────────────────────────────────────────────────────
// QR Ticket Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _QrTicketSheet extends StatelessWidget {
  const _QrTicketSheet({
    required this.deal,
    required this.qrCode,
    required this.paymentMethod,
    required this.onDone,
  });

  final DonationItem deal;
  final String qrCode;
  final String paymentMethod;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final amount = (deal.discountedPrice ?? 150).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Success icon
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primaryEmerald, size: 34),
            ),
            const SizedBox(height: 12),

            const Text(
              'Deal Reserved! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Show this QR to the store staff when you collect your order.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
            const SizedBox(height: 20),

            // QR card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Actual QR code
                  QrImageView(
                    data: qrCode,
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
                  Text(
                    qrCode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  // Amount row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount to pay at store',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary),
                      ),
                      Text(
                        'Rs $amount',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Payment method row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment via',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary),
                      ),
                      Text(
                        paymentMethod,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Food name row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          deal.title,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
