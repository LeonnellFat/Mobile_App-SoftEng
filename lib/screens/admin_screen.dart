import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/flower_type.dart';
import '../models/occasion.dart';
import '../models/category.dart';
import '../models/bouquet_color.dart';
import '../widgets/admin_navigation_bar.dart';
import '../services/supabase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String _activeView = 'dashboard';
  String _searchQuery = '';
  String _orderStatusFilter = 'all';
  // Removed unused selected item fields; restore only if needed by future features

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    final stats = adminProvider.getOrderStats();

    return Scaffold(
      body: Column(
        children: [
          // Admin Header
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Quicksand',
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome back, ${authProvider.user?.name ?? "Admin"}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: () {
                        authProvider.logout();
                        // Use GoRouter to replace the current route with the root
                        context.go('/');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content Area
          Expanded(child: _buildViewContent(adminProvider, stats)),

          // Bottom Navigation
          _buildAdminNavigation(),
        ],
      ),
    );
  }

  Widget _buildViewContent(
    AdminProvider adminProvider,
    Map<String, dynamic> stats,
  ) {
    switch (_activeView) {
      case 'dashboard':
        return _buildDashboard(stats, adminProvider.orders);
      case 'orders':
        return _buildOrdersView(adminProvider);
      case 'products':
        return _buildProductsView(adminProvider);
      case 'flowers':
        return _buildFlowersView(adminProvider);
      case 'categories':
        return _buildCategoriesView(adminProvider);
      case 'bouquet_colors':
        return _buildBouquetColorsView(adminProvider);
      default:
        return _buildDashboard(stats, adminProvider.orders);
    }
  }

  Widget _buildDashboard(Map<String, dynamic> stats, List<Order> orders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.calendar_today,
                  label: 'Orders Today',
                  value: stats['todayOrders'].toString(),
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  label: 'Total Sales',
                  value: '₱${stats['totalRevenue'].toStringAsFixed(2)}',
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Orders
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...orders.take(5).map((order) => _buildOrderListItem(order)),
                ],
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderListItem(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${order.id} • ₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    // Support OrderStatus enum or string names
    String statusStr;
    if (status is OrderStatus) {
      statusStr = status.name;
    } else {
      statusStr = status.toString();
    }

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (statusStr) {
      case 'pending':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        icon = Icons.access_time;
        break;
      case 'confirmed':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.check_circle_outline;
        break;
      case 'preparing':
        bgColor = const Color(0xFFE9D5FF);
        textColor = const Color(0xFF6B21A8);
        icon = Icons.restaurant;
        break;
      case 'ready':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        icon = Icons.inventory;
        break;
      case 'outForDelivery':
      case 'out-for-delivery':
        bgColor = const Color(0xFFFED7AA);
        textColor = const Color(0xFF9A3412);
        icon = Icons.local_shipping;
        break;
      case 'delivered':
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        icon = Icons.cancel;
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusStr == 'delivered' ? '✅ Delivered' : statusStr,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersView(AdminProvider adminProvider) {
    final filteredOrders = adminProvider.orders.where((order) {
      final matchesSearch =
          order.customerName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          order.customerEmail.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _orderStatusFilter == 'all' ||
          order.status.name == _orderStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              hintText: 'Search orders...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        // Status Filter
        _buildStatusFilter(adminProvider.orders),

        // Orders List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(filteredOrders[index], adminProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(List<Order> orders) {
    final statusOptions = [
      'all',
      'pending',
      'confirmed',
      'preparing',
      'ready',
      'cancelled',
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statusOptions.length,
        itemBuilder: (context, index) {
          final status = statusOptions[index];
          final isActive = _orderStatusFilter == status;
          final count = status == 'all'
              ? orders.length
              : orders.where((o) => o.status.name == status).length;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _orderStatusFilter = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primary
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: isActive ? AppTheme.shadowMd : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getStatusIcon(status),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status == 'all'
                          ? 'All'
                          : status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'all':
        return '📋';
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✅';
      case 'preparing':
        return '👩‍🍳';
      case 'ready':
        return '📦';
      case 'delivered':
        return '🚚';
      case 'cancelled':
        return '❌';
      default:
        return '📄';
    }
  }

  Widget _buildOrderCard(Order order, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show order detail dialog
          _showOrderDetailDialog(order, adminProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                order.customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.deliveryType == DeliveryType.pickup
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.deliveryType == DeliveryType.pickup
                                    ? '🏪 Pickup'
                                    : '🚚 Delivery',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      order.deliveryType == DeliveryType.pickup
                                      ? const Color(0xFF1E40AF)
                                      : const Color(0xFF065F46),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customerEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        Text(
                          DateTime.parse(
                            order.orderDate,
                          ).toLocal().toString().substring(0, 16),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        if (order.pickupTime != null)
                          Text(
                            'Pickup: ${order.pickupTime}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${order.items.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailDialog(Order order, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => _OrderDetailDialog(
        order: order,
        onUpdateStatus: (newStatus) {
          // Convert the incoming status name (String) to the OrderStatus enum
          final enumStatus = OrderStatus.values.firstWhere(
            (e) => e.name == newStatus,
            orElse: () => OrderStatus.pending,
          );
          adminProvider.updateOrderStatus(order.id, enumStatus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to $newStatus'),
              backgroundColor: AppTheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsView(AdminProvider adminProvider) {
    final filteredProducts = adminProvider.products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search and Add
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: () => _showProductFormDialog(null, adminProvider),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(filteredProducts[index], adminProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: product.image,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () =>
                            _showProductFormDialog(product, adminProvider),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: Text(
                                'Are you sure you want to delete ${product.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    adminProvider.deleteProduct(product.id);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Product deleted'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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

  void _showProductFormDialog(Product? product, AdminProvider adminProvider) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toStringAsFixed(2) : '',
    );
    final imageController = TextEditingController(text: product?.image ?? '');
    final descController = TextEditingController(
      text: product?.description ?? '',
    );
    final selectedCategories = <String>{};
    String badge = 'None';

    // preselect product category if editing
    if (product != null && product.category.isNotEmpty) {
      selectedCategories.add(product.category);
      badge = product.isBestSeller
          ? 'Bestseller'
          : (product.isTodaysSpecial ? 'Special' : 'None');
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 500,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product == null ? 'Add New Product' : 'Edit Product',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Product Name',
                              hintText: 'e.g., Rose Bouquet',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price (₱)',
                              hintText: 'e.g., 150.00',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: imageController,
                            decoration: const InputDecoration(
                              labelText: 'Image URL',
                              hintText: 'https://...',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: descController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Categories',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: GridView.count(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width < 480
                                  ? 2
                                  : 4,
                              childAspectRatio: 3.8,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              children: adminProvider.categories.map((c) {
                                final isSelected = selectedCategories.contains(
                                  c.name,
                                );
                                return FilterChip(
                                  selected: isSelected,
                                  label: Text(c.name),
                                  onSelected: (v) {
                                    setState(() {
                                      if (v) {
                                        selectedCategories.add(c.name);
                                      } else {
                                        selectedCategories.remove(c.name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: badge,
                            items: ['None', 'Special', 'Bestseller']
                                .map(
                                  (b) => DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => badge = v ?? 'None'),
                            decoration: const InputDecoration(
                              labelText: 'Badge (Optional)',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final price =
                              double.tryParse(priceController.text) ?? 0.0;
                          final image = imageController.text.trim();
                          final desc = descController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Product name is required'),
                              ),
                            );
                            return;
                          }

                          final selectedCategory = selectedCategories.isNotEmpty
                              ? selectedCategories.first
                              : '';

                          final updated = Product(
                            id: product?.id ?? '',
                            name: name,
                            price: price,
                            image: image,
                            category: selectedCategory,
                            description: desc,
                            isTodaysSpecial: badge == 'Special',
                            isBestSeller: badge == 'Bestseller',
                          );

                          if (product == null) {
                            adminProvider.addProduct(updated);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product added')),
                            );
                          } else {
                            adminProvider.updateProduct(product.id, updated);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product updated')),
                            );
                          }

                          Navigator.pop(context);
                        },
                        child: Text(
                          product == null ? 'Add Product' : 'Update Product',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // dispose controllers after closing the dialog when possible
    // they will be garbage-collected after dialog is dismissed
  }

  Widget _buildFlowersView(AdminProvider adminProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Flower Types',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                    color: AppTheme.primary,
                  ),
                ),
              ),
              FloatingActionButton.small(
                onPressed: () => _showFlowerTypeDialog(null, adminProvider),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: adminProvider.flowers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_florist,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text('No flower types available'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: adminProvider.flowers.length,
                  itemBuilder: (context, index) {
                    return _buildFlowerCard(
                      adminProvider.flowers[index],
                      adminProvider,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFlowerCard(FlowerType flower, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CachedNetworkImage(
              imageUrl: flower.image,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flower.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: flower.colors.map((color) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          color,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showFlowerTypeDialog(flower, adminProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Flower Type'),
                        content: Text('Delete ${flower.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await SupabaseService.deleteFlowerType(
                                  flower.id,
                                );
                                adminProvider.deleteFlower(flower.id);
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Flower type deleted'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesView(AdminProvider adminProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Browse by Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Quicksand',
                    color: AppTheme.primary,
                  ),
                ),
              ),
              FloatingActionButton.small(
                onPressed: () => _showCategoryDialog(null, adminProvider),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: adminProvider.categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text('No categories available'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: adminProvider.categories.length,
                  itemBuilder: (context, index) {
                    return _buildCategoryCard(
                      adminProvider.categories[index],
                      adminProvider,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          CachedNetworkImage(
            imageUrl: category.image ?? '',
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorWidget: (c, u, e) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description ?? 'No description',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _showCategoryDialog(category, adminProvider),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Category'),
                      content: Text('Delete ${category.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await SupabaseService.deleteCategory(category.id);
                              adminProvider.deleteOccasion(category.id);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Category deleted'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFlowerTypeDialog(FlowerType? flower, AdminProvider adminProvider) {
    final nameController = TextEditingController(text: flower?.name ?? '');
    final imageController = TextEditingController(text: flower?.image ?? '');
    final colorsController = TextEditingController(
      text: flower?.colors.join(', ') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(flower == null ? 'Add Flower Type' : 'Edit Flower Type'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Rose',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Colors (comma-separated)',
                hintText: 'Red, Pink, White',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final image = imageController.text.trim();
              final colors = colorsController.text
                  .split(',')
                  .map((c) => c.trim())
                  .where((c) => c.isNotEmpty)
                  .toList();
              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Name required')));
                return;
              }
              try {
                if (flower == null) {
                  await SupabaseService.insertFlowerType({
                    'name': name,
                    'image': image.isNotEmpty
                        ? image
                        : 'https://images.unsplash.com/photo-1599599810694-b5ac4dd13413?w=800',
                    'colors': colors,
                  });
                  adminProvider.addFlower(
                    FlowerType(
                      id: DateTime.now().toString(),
                      name: name,
                      image: image,
                      colors: colors,
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flower type added')),
                    );
                  }
                } else {
                  await SupabaseService.updateFlowerType(flower.id, {
                    'name': name,
                    'image': image,
                    'colors': colors,
                  });
                  adminProvider.updateFlower(
                    flower.id,
                    FlowerType(
                      id: flower.id,
                      name: name,
                      image: image,
                      colors: colors,
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flower type updated')),
                    );
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(flower == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(Category? category, AdminProvider adminProvider) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(
      text: category?.description ?? '',
    );
    final imageController = TextEditingController(text: category?.image ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Birthday',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 12),
            if (imageController.text.isNotEmpty)
              Image.network(
                imageController.text,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final image = imageController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Name required')));
                return;
              }
              try {
                if (category == null) {
                  final res = await SupabaseService.insertCategory({
                    'name': name,
                    'description': desc,
                    'image': image.isNotEmpty
                        ? image
                        : 'https://images.unsplash.com/photo-1599599810694-b5ac4dd13413?w=800',
                  });
                  final newCat = Category.fromMap(res);
                  adminProvider.addOccasion(
                    Occasion(
                      id: newCat.id,
                      name: newCat.name,
                      image: newCat.image ?? '',
                      description: newCat.description ?? '',
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category added')),
                    );
                  }
                } else {
                  await SupabaseService.updateCategory(category.id, {
                    'name': name,
                    'description': desc,
                    'image': image.isNotEmpty ? image : category.image,
                  });
                  adminProvider.deleteOccasion(category.id);
                  adminProvider.addOccasion(
                    Occasion(
                      id: category.id,
                      name: name,
                      image: image.isNotEmpty ? image : category.image ?? '',
                      description: desc,
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category updated')),
                    );
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(category == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildBouquetColorsView(AdminProvider adminProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bouquet Colors',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Color'),
                onPressed: () {
                  // Show add color dialog
                  _showBouquetColorDialog(context, adminProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (adminProvider.bouquetColors.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No bouquet colors yet',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: adminProvider.bouquetColors.length,
              itemBuilder: (context, index) {
                final color = adminProvider.bouquetColors[index];
                final hexColor = color.hexCode != null
                    ? int.tryParse(color.hexCode!.replaceFirst('#', '0xff'))
                    : null;

                return Card(
                  child: Stack(
                    children: [
                      // Color preview
                      Container(
                        decoration: BoxDecoration(
                          color: hexColor != null
                              ? Color(hexColor)
                              : Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        height: 100,
                      ),
                      // Info
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                color.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (color.hexCode != null)
                                Text(
                                  color.hexCode!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Edit/Delete buttons
                      Positioned(
                        top: 4,
                        right: 4,
                        child: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Text('Edit'),
                              onTap: () => _showBouquetColorDialog(
                                context,
                                adminProvider,
                                color,
                              ),
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () async {
                                try {
                                  await SupabaseService.deleteBouquetColor(
                                    color.id,
                                  );
                                  adminProvider.deleteBouquetColor(color.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Color deleted'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showBouquetColorDialog(
    BuildContext context,
    AdminProvider adminProvider, [
    BouquetColor? existingColor,
  ]) {
    final nameController = TextEditingController(
      text: existingColor?.name ?? '',
    );
    final hexCodeController = TextEditingController(
      text: existingColor?.hexCode ?? '#FF69B4',
    );
    final descriptionController = TextEditingController(
      text: existingColor?.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingColor == null ? 'Add Color' : 'Edit Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Color Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hexCodeController,
                decoration: const InputDecoration(
                  labelText: 'Hex Code',
                  hintText: '#FF69B4',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Name required')));
                return;
              }
              try {
                if (existingColor == null) {
                  await SupabaseService.insertBouquetColor({
                    'name': nameController.text,
                    'hex_code': hexCodeController.text,
                    'description': descriptionController.text,
                  });
                  adminProvider.addBouquetColor(
                    BouquetColor(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      hexCode: hexCodeController.text,
                      description: descriptionController.text,
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Color added')),
                    );
                  }
                } else {
                  await SupabaseService.updateBouquetColor(existingColor.id, {
                    'name': nameController.text,
                    'hex_code': hexCodeController.text,
                    'description': descriptionController.text,
                  });
                  adminProvider.updateBouquetColor(
                    existingColor.id,
                    BouquetColor(
                      id: existingColor.id,
                      name: nameController.text,
                      hexCode: hexCodeController.text,
                      description: descriptionController.text,
                    ),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Color updated')),
                    );
                  }
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNavigation() {
    return AdminNavigationBar(
      activeTab: _activeView,
      onTabChange: (tab) => setState(() => _activeView = tab),
    );
  }
}

class _OrderDetailDialog extends StatelessWidget {
  final Order order;
  final Function(String) onUpdateStatus;

  const _OrderDetailDialog({required this.order, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.cancelled,
    ];

    return AlertDialog(
      title: Text('Order ${order.id}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info
            const Text(
              'Customer Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name:', order.customerName),
            _buildInfoRow('Email:', order.customerEmail),
            _buildInfoRow('Phone:', order.customerPhone),
            _buildInfoRow('Address:', order.customerAddress),

            const SizedBox(height: 20),

            // Status indicator if delivered
            if (order.status == OrderStatus.delivered)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Delivered',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This order has been marked as delivered by the driver.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Status Update Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statusOptions.map((status) {
                      final isActive = order.status == status;
                      return ElevatedButton(
                        onPressed: () {
                          onUpdateStatus(status.name);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActive
                              ? AppTheme.primary
                              : Colors.white,
                          foregroundColor: isActive
                              ? Colors.white
                              : Colors.black87,
                          side: BorderSide(
                            color: isActive
                                ? AppTheme.primary
                                : const Color(0xFFE5E7EB),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          status.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Order Items
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity}x ${item.product.name}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '₱${(item.product.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                Text(
                  '₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
