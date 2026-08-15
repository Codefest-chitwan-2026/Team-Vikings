import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sponsorship_provider.dart';

class SponsorBatchScreen extends StatefulWidget {
  const SponsorBatchScreen({super.key, required this.donation});

  final DonationItem donation;

  @override
  State<SponsorBatchScreen> createState() => _SponsorBatchScreenState();
}

class _SponsorBatchScreenState extends State<SponsorBatchScreen> {
  // ── Amount state ──────────────────────────────────────────────────────────
  static const _quickAmounts = [100, 500, 1000, 2000];
  int _selectedQuickAmount = 500;
  final TextEditingController _customAmountController =
      TextEditingController(text: '500');
  bool _isCustomAmount = false;

  // ── Payment method state ──────────────────────────────────────────────────
  String _selectedPayment = 'eSewa';

  static const _paymentMethods = [
    _PaymentMethod(
      id: 'eSewa',
      label: 'eSewa',
      subtitle: 'Mobile Wallet',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF60BB46),
    ),
    _PaymentMethod(
      id: 'Khalti',
      label: 'Khalti',
      subtitle: 'Digital Wallet',
      icon: Icons.payment_rounded,
      color: Color(0xFF5C2D91),
    ),
    _PaymentMethod(
      id: 'IME Pay',
      label: 'IME Pay',
      subtitle: 'Mobile Banking',
      icon: Icons.phone_android_rounded,
      color: Color(0xFFE53935),
    ),
  ];

  // ── Message state ─────────────────────────────────────────────────────────
  final TextEditingController _messageController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  int get _effectiveAmount {
    if (_isCustomAmount) {
      return int.tryParse(_customAmountController.text.trim()) ??
          _selectedQuickAmount;
    }
    return _selectedQuickAmount;
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _selectedQuickAmount = amount;
      _isCustomAmount = false;
      _customAmountController.text = amount.toString();
    });
  }

  Future<void> _donate() async {
    final amount = _effectiveAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<SponsorshipProvider>();
    final token = auth.currentUser?.token;

    final success = await provider.createSponsorship(
      token: token,
      surplusItemId: widget.donation.id,
      foodTitle: widget.donation.title,
      donorName: widget.donation.donorBusinessName ?? 'Local Business',
      mealsCount: widget.donation.quantity,
      amount: amount.toDouble(),
      originalValue: amount.toDouble(),
      dedication: _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      _showSuccessSheet(amount);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.errorMessage ?? 'Donation failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessSheet(int amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SuccessSheet(
        donation: widget.donation,
        amount: amount,
        paymentMethod: _selectedPayment,
        onDone: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.donation;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.charcoal),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Sponsor this Batch',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            // ── Batch Summary Card ─────────────────────────────────────
            _BatchSummaryCard(donation: d),
            const SizedBox(height: 24),

            // ── Amount section ─────────────────────────────────────────
            _sectionHeading('Enter amount to give'),
            const SizedBox(height: 12),
            _AmountInputSection(
              controller: _customAmountController,
              quickAmounts: _quickAmounts,
              selectedQuickAmount: _selectedQuickAmount,
              isCustom: _isCustomAmount,
              onQuickSelect: _selectQuickAmount,
              onCustomChanged: (v) {
                setState(() => _isCustomAmount = true);
              },
            ),
            const SizedBox(height: 24),

            // ── Message field ──────────────────────────────────────────
            _sectionHeading('Message (optional)'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText:
                      'Leave a message for the donor or NGO (e.g. "Keep up the great work!")…',
                  hintStyle:
                      TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Payment method ─────────────────────────────────────────
            _sectionHeading('Pay with'),
            const SizedBox(height: 12),
            _PaymentMethodSection(
              methods: _paymentMethods,
              selected: _selectedPayment,
              onSelect: (id) => setState(() => _selectedPayment = id),
            ),
            const SizedBox(height: 28),

            // ── 100% goes row ──────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded,
                      size: 16, color: AppColors.primaryEmerald),
                  SizedBox(width: 8),
                  Text(
                    '100% goes to rescue logistics',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Donate Now button ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _donate,
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
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Donate Now · Rs $_effectiveAmount',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Batch Summary Card ─────────────────────────────────────────────────────

class _BatchSummaryCard extends StatelessWidget {
  const _BatchSummaryCard({required this.donation});

  final DonationItem donation;

  static String _emoji(FoodCategory cat) {
    switch (cat) {
      case FoodCategory.veg:
        return '🥗';
      case FoodCategory.nonVeg:
        return '🍗';
      case FoodCategory.mixed:
        return '🥐';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _emoji(donation.category),
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donor name
                Text(
                  donation.donorBusinessName?.isNotEmpty == true
                      ? donation.donorBusinessName!
                      : 'Local Food Business',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryEmerald,
                  ),
                ),
                const SizedBox(height: 4),

                // Food title
                Text(
                  donation.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Chips row
                Row(
                  children: [
                    _summaryChip(Icons.inventory_2_outlined,
                        '${donation.quantity} ${donation.quantityUnit}'),
                    const SizedBox(width: 6),
                    _summaryChip(
                        Icons.schedule_outlined, donation.pickupWindow),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        donation.pickupAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // FREE badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      AppColors.primaryEmerald.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'FREE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Amount Input Section ───────────────────────────────────────────────────

class _AmountInputSection extends StatelessWidget {
  const _AmountInputSection({
    required this.controller,
    required this.quickAmounts,
    required this.selectedQuickAmount,
    required this.isCustom,
    required this.onQuickSelect,
    required this.onCustomChanged,
  });

  final TextEditingController controller;
  final List<int> quickAmounts;
  final int selectedQuickAmount;
  final bool isCustom;
  final ValueChanged<int> onQuickSelect;
  final ValueChanged<String> onCustomChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Amount text field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryEmerald,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                      right: BorderSide(color: AppColors.border)),
                ),
                child: const Text(
                  'Rs',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onCustomChanged,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        fontSize: 18, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Quick amount chips
        Row(
          children: quickAmounts.map((amount) {
            final isSelected = !isCustom && selectedQuickAmount == amount;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: amount != quickAmounts.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onQuickSelect(amount),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryEmerald
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Rs $amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Payment Method Section ─────────────────────────────────────────────────

class _PaymentMethod {
  const _PaymentMethod({
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

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.methods,
    required this.selected,
    required this.onSelect,
  });

  final List<_PaymentMethod> methods;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: methods.map((m) {
        final isSelected = selected == m.id;
        return Padding(
          padding:
              EdgeInsets.only(bottom: m.id != methods.last.id ? 10 : 0),
          child: GestureDetector(
            onTap: () => onSelect(m.id),
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
                  color: isSelected
                      ? m.color
                      : AppColors.border,
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon circle
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

                  // Label
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

                  // Radio circle
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
                      color:
                          isSelected ? Colors.white : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Success Bottom Sheet ───────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.donation,
    required this.amount,
    required this.paymentMethod,
    required this.onDone,
  });

  final DonationItem donation;
  final int amount;
  final String paymentMethod;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: AppColors.primaryEmerald,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Donation Successful! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thank you for sponsoring this batch.\nYour contribution helps food reach those who need it most.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _successRow('Food batch',
                      donation.title, false),
                  const Divider(height: 16, color: AppColors.border),
                  _successRow('Amount donated',
                      'Rs $amount', true),
                  const Divider(height: 16, color: AppColors.border),
                  _successRow('Via', paymentMethod, false),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                  style: TextStyle(
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

  Widget _successRow(String label, String value, bool highlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? AppColors.primaryEmerald
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
