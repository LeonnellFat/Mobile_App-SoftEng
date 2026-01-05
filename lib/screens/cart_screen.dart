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

    final subtotal = cartProvider.getSubtotal();
    final deliveryFee = _deliveryOption == 'delivery' ? 5.99 : 0.0;
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
                      Text(
                        'Shopping Cart',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${cartItems.length} items in your cart',
                        style: Theme.of(context).textTheme.bodySmall,
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
            child: ElevatedButton(
              onPressed: () {
                if (!authProvider.isLoggedIn) {
                  authProvider.setShowGuestModal(true);
                  return;
                }

                showDialog(
                  context: context,
                  builder: (context) => CheckoutDialog(
                    total: total,
                    deliveryOption: _deliveryOption,
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

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        16,
                        maxSize: 18,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${item.product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primary,
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
            SizedBox(
              width: ResponsiveHelper.getResponsiveSpacing(
                context,
                small: 12,
                medium: 14,
                large: 16,
              ),
            ),

            // Quantity Controls
            Column(
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
            // Delivery option: custom selectable tiles (replaces deprecated RadioListTile)
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
                          Text('Same day delivery - ₱5.99'),
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
