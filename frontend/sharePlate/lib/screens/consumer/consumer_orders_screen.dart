import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/donation_model.dart';

enum _OrderFilter { all, active, completed }

enum OrderStatus { readyForPickup, completed }

class _ConsumerOrder {
  final String id;
  final String title;
  final String storeName;
  final String storePhone;
  final String pickupAddress;
  final double distanceKm;
  final double originalPrice;
  final double discountedPrice;
  final FoodCategory category;
  final String orderCode;
  final DateTime orderTime;
  final int pickupWindowMinutes;
  final String instructions;
  OrderStatus status;

  _ConsumerOrder({
    required this.id,
    required this.title,
    required this.storeName,
    required this.storePhone,
    required this.pickupAddress,
    required this.distanceKm,
    required this.originalPrice,
    required this.discountedPrice,
    required this.category,
    required this.orderCode,
    required this.orderTime,
    required this.pickupWindowMinutes,
    required this.instructions,
    this.status = OrderStatus.readyForPickup,
  });

  bool get isActive => status == OrderStatus.readyForPickup;

  double get savedAmount => originalPrice - discountedPrice;
}

class ConsumerOrdersScreen extends StatefulWidget {
  const ConsumerOrdersScreen({super.key});

  @override
  State<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends State<ConsumerOrdersScreen> {
  _OrderFilter _selectedFilter = _OrderFilter.all;
  String _searchQuery = '';

  late List<_ConsumerOrder> _orders;

  @override
  void initState() {
    super.initState();
    _orders = [
      _ConsumerOrder(
        id: 'ord-1',
        title: 'Assorted Gourmet Pastry Box (4 pcs)',
        storeName: 'Chitwan Black Forest Cafe',
        storePhone: '9855012345',
        pickupAddress: 'Narayangarh Chowk, Chitwan',
        distanceKm: 0.8,
        originalPrice: 450,
        discountedPrice: 180,
        category: FoodCategory.veg,
        orderCode: 'ORD-5542',
        orderTime: DateTime.now().subtract(const Duration(minutes: 20)),
        pickupWindowMinutes: 40,
        instructions: 'Show your order code at the cash counter to collect your fresh box.',
        status: OrderStatus.readyForPickup,
      ),
      _ConsumerOrder(
        id: 'ord-2',
        title: 'Deluxe Chicken Biryani Bowl & Raita',
        storeName: 'Himalayan Grill & Kitchen',
        storePhone: '9841987654',
        pickupAddress: 'Bharatpur Height-10, Chitwan',
        distanceKm: 2.1,
        originalPrice: 380,
        discountedPrice: 150,
        category: FoodCategory.nonVeg,
        orderCode: 'ORD-9812',
        orderTime: DateTime.now().subtract(const Duration(minutes: 45)),
        pickupWindowMinutes: 50,
        instructions: 'Packed hot and ready at the takeaway pickup station.',
        status: OrderStatus.readyForPickup,
      ),
      _ConsumerOrder(
        id: 'ord-3',
        title: 'Freshly Baked Artisanal Sourdough Bread',
        storeName: 'The French Bakery',
        storePhone: '9801234888',
        pickupAddress: 'Lions Chowk, Narayangarh',
        distanceKm: 1.5,
        originalPrice: 280,
        discountedPrice: 99,
        category: FoodCategory.veg,
        orderCode: 'ORD-1049',
        orderTime: DateTime.now().subtract(const Duration(hours: 4)),
        pickupWindowMinutes: 60,
        instructions: 'Collected with verified order code.',
        status: OrderStatus.completed,
      ),
    ];
  }

  List<_ConsumerOrder> get _filteredOrders {
    return _orders.where((order) {
      if (_selectedFilter == _OrderFilter.active && !order.isActive) {
        return false;
      }
      if (_selectedFilter == _OrderFilter.completed && order.isActive) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return order.title.toLowerCase().contains(q) ||
            order.storeName.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _showPickupDetails(_ConsumerOrder order) {
    showModalBottomSheet(
      context: context,
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pickup Verification Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Present this code at ${order.storeName} during pickup',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, size: 28, color: AppColors.primaryEmerald),
                    const SizedBox(width: 12),
                    Text(
                      order.orderCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                order.instructions,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;
    final activeCount = _orders.where((o) => o.isActive).length;
    final completedCount = _orders.where((o) => !o.isActive).length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                          'My Orders & Claims',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Reserved discount deals & flash sale pickups',
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
                          const Icon(Icons.shopping_bag_outlined,
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

                // Search Bar
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search orders or food items...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Buttons
                Row(
                  children: [
                    _filterButton('All (${_orders.length})', _OrderFilter.all),
                    const SizedBox(width: 8),
                    _filterButton('Active Pickups ($activeCount)', _OrderFilter.active),
                    const SizedBox(width: 8),
                    _filterButton('Past Orders ($completedCount)', _OrderFilter.completed),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No orders or claims found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Explore Flash Deals from local cafes and bakeries to save food and money.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, _OrderFilter filter) {
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

  Widget _buildOrderCard(_ConsumerOrder order) {
    final isActive = order.isActive;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primaryEmerald.withValues(alpha: 0.35)
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
            // Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE4F6E9)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.timer_outlined
                            : Icons.check_circle_rounded,
                        size: 13,
                        color: isActive
                            ? const Color(0xFF2E7D32)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Ready for Pickup' : 'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Title
            Text(
              order.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),

            // Price & Savings
            Row(
              children: [
                Text(
                  'Rs ${order.discountedPrice.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryEmerald,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs ${order.originalPrice.toInt()}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Saved Rs ${order.savedAmount.toInt()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Store Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.storeName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${order.distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.pickupAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPickupDetails(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Show Code',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order "${order.title}" marked as received'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Received',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order "${order.title}" confirmed'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Confirmed',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
