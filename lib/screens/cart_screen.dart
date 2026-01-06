import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/checkout_dialog.dart';
import '../utils/responsive_helper.dart';

class CartScreen extends StatefulWidget {
  final Function(String)? onNavigate;

  const CartScreen({super.key, this.onNavigate});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _deliveryOption = 'delivery';

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartItems = cartProvider.cartItems;
    final horizontalPadding = ResponsiveHelper.getResponsiveHorizontalPadding(
      context,
    );

    if (cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    final subtotal = cartProvider.getSelectedSubtotal();
    final deliveryFee = _deliveryOption == 'delivery' ? 60.0 : 0.0;
    final tax = subtotal * 0.08;
    final total = subtotal + deliveryFee + tax;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shopping Cart',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: AppTheme.primary),
                          ),
                          Chip(
                            label: Text(
                              '${cartProvider.getSelectedItemCount()}/${cartItems.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppTheme.primary.withAlpha(30),
                            labelStyle: const TextStyle(
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${cartItems.length} items in your cart',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              if (cartProvider.areAllItemsSelected()) {
                                cartProvider.deselectAllItems();
                              } else {
                                cartProvider.selectAllItems();
                              }
                            },
                            icon: cartProvider.areAllItemsSelected()
                                ? const Icon(Icons.check_circle)
                                : const Icon(Icons.circle_outlined),
                            label: cartProvider.areAllItemsSelected()
                                ? const Text('Deselect All')
                                : const Text('Select All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Cart Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(horizontalPadding),
                children: [
                  // Items
                  ...cartItems.map(
                    (item) => _buildCartItem(item, cartProvider),
                  ),

                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(
                      context,
                      small: 16,
                      medium: 20,
                      large: 24,
                    ),
                  ),

                  // Delivery Options
                  _buildDeliveryOptions(),

                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(
                      context,
                      small: 16,
                      medium: 20,
                      large: 24,
                    ),
                  ),

                  // Order Summary
                  _buildOrderSummary(subtotal, deliveryFee, tax, total),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

      // Checkout Button
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(
              ResponsiveHelper.getResponsiveHorizontalPadding(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cartProvider.getSelectedItemCount() == 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select at least one item to proceed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: cartProvider.getSelectedItemCount() == 0
                      ? null
                      : () {
                          if (!authProvider.isLoggedIn) {
                            authProvider.setShowGuestModal(true);
                            return;
                          }

                          showDialog(
                            context: context,
                            builder: (context) => CheckoutDialog(
                              total: total,
                              deliveryOption: _deliveryOption,
                              selectedItems: cartProvider.getSelectedItems(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card),
                      const SizedBox(width: 12),
                      Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            16,
                            maxSize: 18,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    final horizontalPadding = ResponsiveHelper.getResponsiveHorizontalPadding(
      context,
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shopping Cart',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(
                          ResponsiveHelper.getResponsiveHorizontalPadding(
                            context,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🛒', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 24),
                            Text(
                              'Your cart is empty',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add some beautiful flowers to get started!',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.mutedForeground),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to the products tab using go_router
                                GoRouter.of(context).go('/products');
                              },
                              child: const Text('Start Shopping'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(dynamic item, CartProvider cartProvider) {
    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(
          context,
          small: 12,
          medium: 14,
          large: 16,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.getResponsiveSpacing(
            context,
            small: 12,
            medium: 14,
            large: 16,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            SizedBox(
              width: 40,
              child: Center(
                child: Checkbox(
                  value: item.isSelected ?? true,
                  onChanged: (_) {
                    cartProvider.toggleItemSelection(item.product.id);
                  },
                  activeColor: AppTheme.primary,
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(
                context,
                small: 8,
                medium: 10,
                large: 12,
              ),
            ),

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: CachedNetworkImage(
                imageUrl: item.product.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade100,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(
                context,
                small: 12,
                medium: 14,
                large: 16,
              ),
            ),

            // Details and Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                        maxSize: 16,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        14,
                        maxSize: 16,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(
                context,
                small: 8,
                medium: 10,
                large: 12,
              ),
            ),

            // Quantity Controls
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    cartProvider.removeFromCart(item.product.id);
                  },
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: () {
                        cartProvider.updateQuantity(
                          item.product.id,
                          item.quantity - 1,
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        item.quantity.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () {
                        cartProvider.updateQuantity(
                          item.product.id,
                          item.quantity + 1,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.getResponsiveSpacing(
            context,
            small: 16,
            medium: 20,
            large: 24,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  20,
                  maxSize: 24,
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(
                context,
                small: 12,
                medium: 14,
                large: 16,
              ),
            ),
            // Delivery option: Home Delivery only
            GestureDetector(
              onTap: () => setState(() => _deliveryOption = 'delivery'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Home Delivery'),
                          SizedBox(height: 2),
                          Text('Delivery fee - ₱60.00'),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _deliveryOption == 'delivery'
                            ? AppTheme.primary
                            : null,
                        border: _deliveryOption == 'delivery'
                            ? null
                            : Border.all(color: AppTheme.border),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _deliveryOption = 'pickup'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Store Pickup'),
                          SizedBox(height: 2),
                          Text('Ready in 30-45 minutes - Free'),
                        ],
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _deliveryOption == 'pickup'
                            ? AppTheme.primary
                            : null,
                        border: _deliveryOption == 'pickup'
                            ? null
                            : Border.all(color: AppTheme.border),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    double subtotal,
    double deliveryFee,
    double tax,
    double total,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.getResponsiveSpacing(
            context,
            small: 16,
            medium: 20,
            large: 24,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  20,
                  maxSize: 24,
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(
                context,
                small: 12,
                medium: 14,
                large: 16,
              ),
            ),
            _buildSummaryRow('Subtotal', subtotal),
            _buildSummaryRow(
              _deliveryOption == 'delivery' ? 'Delivery Fee' : 'Pickup Fee',
              deliveryFee,
            ),
            _buildSummaryRow('Tax', tax),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      20,
                      maxSize: 24,
                    ),
                  ),
                ),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      20,
                      maxSize: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text('₱${amount.toStringAsFixed(2)}')],
      ),
    );
  }
}
