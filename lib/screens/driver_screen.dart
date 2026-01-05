import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _showTransactionHistory = false;
  final int _ordersPerBatch = 5;
  int _visibleReadyCount = 5;
  int _visibleOutForDeliveryCount = 5;

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Filter orders
    final readyOrders =
        adminProvider.orders
            .where(
              (order) =>
                  order.deliveryType == DeliveryType.delivery &&
                  order.status == OrderStatus.ready,
            )
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              a.orderDate,
            ).compareTo(DateTime.parse(b.orderDate)),
          );

    final outForDeliveryOrders =
        adminProvider.orders
            .where(
              (order) =>
                  order.deliveryType == DeliveryType.delivery &&
                  order.status == OrderStatus.outForDelivery,
            )
            .toList()
          ..sort(
            (a, b) => DateTime.parse(
              a.orderDate,
            ).compareTo(DateTime.parse(b.orderDate)),
          );

    final completedOrders = adminProvider.orders
        .where(
          (order) =>
              order.deliveryType == DeliveryType.delivery &&
              order.status == OrderStatus.delivered,
        )
        .toList();

    final activeOrdersCount = readyOrders.length + outForDeliveryOrders.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withAlpha((0.2 * 255).round()),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(
                            (0.2 * 255).round(),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          size: 32,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🚚 Driver Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Quicksand',
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              'Welcome back, ${authProvider.user?.name ?? "Driver"}!',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.red),
                        onPressed: () {
                          authProvider.logout();
                          // Use the router to navigate to root after logout
                          context.go('/');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.inventory,
                      label: 'Ready',
                      value: readyOrders.length.toString(),
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_shipping,
                      label: 'On Route',
                      value: outForDeliveryOrders.length.toString(),
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _showTransactionHistory = true),
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: completedOrders.length.toString(),
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders Content
            Expanded(
              child: _showTransactionHistory
                  ? _buildTransactionHistory(completedOrders)
                  : _buildActiveOrders(
                      readyOrders,
                      outForDeliveryOrders,
                      activeOrdersCount,
                      adminProvider,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withAlpha((0.7 * 255).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrders(
    List<Order> readyOrders,
    List<Order> outForDeliveryOrders,
    int activeOrdersCount,
    AdminProvider adminProvider,
  ) {
    if (activeOrdersCount == 0) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🚚', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'No Active Deliveries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All delivery orders are completed. Great job!',
                  style: TextStyle(color: AppTheme.mutedForeground),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ready for Pickup Section
          if (readyOrders.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.inventory, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Ready for Pickup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    readyOrders.length.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...readyOrders
                .take(_visibleReadyCount)
                .map((order) => _buildOrderCard(order, adminProvider)),
            if (readyOrders.length > _visibleReadyCount)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _visibleReadyCount += _ordersPerBatch;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                  ),
                  child: Text(
                    'Load More (${readyOrders.length - _visibleReadyCount} remaining)',
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],

          // Out for Delivery Section
          if (outForDeliveryOrders.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.local_shipping,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Out for Delivery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    outForDeliveryOrders.length.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...outForDeliveryOrders
                .take(_visibleOutForDeliveryCount)
                .map((order) => _buildOrderCard(order, adminProvider)),
            if (outForDeliveryOrders.length > _visibleOutForDeliveryCount)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _visibleOutForDeliveryCount += _ordersPerBatch;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.purple),
                    foregroundColor: Colors.purple,
                  ),
                  child: Text(
                    'Load More (${outForDeliveryOrders.length - _visibleOutForDeliveryCount} remaining)',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order ${order.id}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSmallStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateTime.parse(order.orderDate).toLocal().toString().substring(0, 16)} • ₱${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer Info
            _buildInfoRow(Icons.person, order.customerName),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _makePhoneCall(order.customerPhone),
              child: _buildInfoRow(
                Icons.phone,
                order.customerPhone,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, order.customerAddress),

            const SizedBox(height: 12),

            // Order Items
            Text(
              'Order Items:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₱${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Note: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                if (order.status == OrderStatus.ready)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        adminProvider.updateOrderStatus(
                          order.id,
                          OrderStatus.outForDelivery,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order marked as Out for Delivery'),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_shipping, size: 18),
                      label: const Text('Start Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (order.status == OrderStatus.outForDelivery)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        adminProvider.updateOrderStatus(
                          order.id,
                          OrderStatus.delivered,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order marked as Delivered'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark Delivered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _makePhoneCall(order.customerPhone),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? AppTheme.mutedForeground),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: color)),
        ),
      ],
    );
  }

  Widget _buildSmallStatusBadge(dynamic status) {
    final statusStr = status is OrderStatus ? status.name : status.toString();
    Color bgColor;
    Color textColor;

    switch (statusStr) {
      case 'ready':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'outForDelivery':
      case 'out-for-delivery':
        bgColor = const Color(0xFFE9D5FF);
        textColor = const Color(0xFF6B21A8);
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    final label = statusStr
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? (word[0].toUpperCase() + word.substring(1))
              : '',
        )
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<Order> completedOrders) {
    final today = DateTime.now();
    final todayDeliveries = completedOrders.where((order) {
      final orderDate = DateTime.parse(order.orderDate);
      return orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).toList();

    final totalEarnings = todayDeliveries.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                onPressed: () =>
                    setState(() => _showTransactionHistory = false),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Transaction History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Quicksand',
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      "Today's completed deliveries",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFFD1FAE5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          todayDeliveries.length.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const Text(
                          'Deliveries',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const Text(
                          'Total Value',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Completed Orders List
        Expanded(
          child: todayDeliveries.isEmpty
              ? Center(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📦', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          const Text(
                            'No Deliveries Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No completed deliveries found for today.',
                            style: TextStyle(color: AppTheme.mutedForeground),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: todayDeliveries.length,
                  itemBuilder: (context, index) {
                    final order = todayDeliveries[index];
                    return Card(
                      color: const Color(0xFFF0FDF4),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Order ${order.id}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Delivered',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.person, order.customerName),
                            const SizedBox(height: 4),
                            _buildInfoRow(Icons.phone, order.customerPhone),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              Icons.location_on,
                              order.customerAddress,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                                Text(
                                  '₱${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }
}
