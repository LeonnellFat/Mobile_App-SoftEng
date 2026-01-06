import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class CheckoutDialog extends StatefulWidget {
  final double total;
  final String deliveryOption;
  final List<dynamic>? selectedItems;

  const CheckoutDialog({
    super.key,
    required this.total,
    required this.deliveryOption,
    this.selectedItems,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  int _currentStep = 0;
  String _pickupTime = '';

  final _addressFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 500;

    final dialogWidth = isSmallScreen
        ? screenWidth * 0.9
        : min(screenWidth * 0.8, 500.0);
    final dialogHeight = screenHeight * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _currentStep == 0
                          ? (widget.deliveryOption == 'pickup'
                                ? 'Order Store Pickup'
                                : 'Delivery Information')
                          : _currentStep == 1
                          ? 'Confirm Order'
                          : 'Order Confirmed',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primary,
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildStepContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return _buildAddressStep();
    } else if (_currentStep == 1) {
      return _buildPaymentStep();
    } else {
      return _buildSuccessStep();
    }
  }

  Widget _buildAddressStep() {
    if (widget.deliveryOption == 'pickup') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store, size: 64, color: AppTheme.primary),
            const SizedBox(height: 24),
            Text('Store Pickup', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha((0.05 * 255).round()),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Jean's Flower Shop",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Dr Miciano Rd'),
                  const Text('Dumaguete City'),
                  const SizedBox(height: 12),
                  const Text(
                    'Store Hours:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Mon-Fri: 8:00 AM - 8:00 PM'),
                  const Text('Sat-Sun: 9:00 AM - 7:00 PM'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Call us: 0936 047 9432',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Preferred Pickup Time *',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'ASAP (30-45 minutes)',
                  child: Text('ASAP (30-45 minutes)'),
                ),
                DropdownMenuItem(value: '1-2 hours', child: Text('1-2 hours')),
                DropdownMenuItem(value: '2-4 hours', child: Text('2-4 hours')),
                DropdownMenuItem(
                  value: 'Tomorrow morning (9-12 PM)',
                  child: Text('Tomorrow morning (9-12 PM)'),
                ),
                DropdownMenuItem(
                  value: 'Tomorrow afternoon (12-5 PM)',
                  child: Text('Tomorrow afternoon (12-5 PM)'),
                ),
                DropdownMenuItem(
                  value: 'Tomorrow evening (5-8 PM)',
                  child: Text('Tomorrow evening (5-8 PM)'),
                ),
              ],
              initialValue: _pickupTime.isEmpty ? null : _pickupTime,
              onChanged: (value) {
                setState(() {
                  _pickupTime = value ?? '';
                });
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber[800],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pickup Instructions:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Please bring a valid ID for order verification\n'
                    '• We\'ll send you a text when your order is ready\n'
                    '• Orders not picked up within 24 hours may be cancelled\n'
                    '• Free parking available in front of the store',
                    style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pickupTime.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                child: const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _addressFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name *'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street Address *'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City *'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(labelText: 'ZIP Code'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions',
                hintText: 'Leave at door, ring doorbell, etc.',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_addressFormKey.currentState!.validate()) {
                    setState(() {
                      _currentStep = 1;
                    });
                  }
                },
                child: const Text('Continue to Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wallet, color: Color(0xFF4CAF50), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Cash Payment',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pay when you receive your order',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Order Summary
          Text(
            'Order Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Different summary based on delivery option
          if (widget.deliveryOption == 'pickup') ...[
            _buildOrderSummaryRow('Pickup Time:', _pickupTime),
            const SizedBox(height: 8),
            _buildOrderSummaryRow('Location:', "Jean's Flower Shop"),
            const SizedBox(height: 8),
            _buildOrderSummaryRow('Address:', 'Dr Miciano Rd, Dumaguete City'),
          ] else ...[
            _buildOrderSummaryRow('Delivery to:', _nameController.text),
            const SizedBox(height: 8),
            _buildOrderSummaryRow(
              'Address:',
              '${_streetController.text}, ${_cityController.text}',
            ),
            const SizedBox(height: 8),
            _buildOrderSummaryRow('Phone:', _phoneController.text),
          ],

          const Divider(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount:',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '₱${widget.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[800],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.deliveryOption == 'pickup'
                      ? '• Please prepare exact change if possible\n'
                            '• Payment will be collected upon pickup\n'
                            '• Cash only - no credit/debit cards accepted'
                      : '• Please prepare exact change if possible\n'
                            '• Payment will be collected upon delivery\n'
                            '• Cash only - no credit/debit cards accepted',
                  style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _processOrder();
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Place Order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Order Confirmed!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you for your order. You\'ll receive a confirmation email shortly.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.deliveryOption == 'delivery'
                ? 'Your flowers will be delivered within the next 2-4 hours.'
                : 'We\'ll text you when your order is ready for pickup!',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _processOrder() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    // Create order
    final customerName = widget.deliveryOption == 'delivery'
        ? _nameController.text
        : user.name;
    final customerAddress = widget.deliveryOption == 'delivery'
        ? '${_streetController.text}, ${_cityController.text}'
        : 'Store Pickup';
    final customerPhone = widget.deliveryOption == 'delivery'
        ? _phoneController.text
        : user.phone;

    // Use selected items if provided, otherwise use all items
    final itemsToOrder = widget.selectedItems ?? cartProvider.cartItems;

    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      customerName: customerName,
      customerEmail: user.email,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      items: itemsToOrder
          .map(
            (item) => CartItem(product: item.product, quantity: item.quantity),
          )
          .toList(),
      total: widget.total,
      status: OrderStatus.pending,
      orderDate: DateTime.now().toIso8601String(),
      deliveryDate: widget.deliveryOption == 'delivery'
          ? DateTime.now().add(const Duration(hours: 4)).toIso8601String()
          : DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      notes: widget.deliveryOption == 'delivery'
          ? _instructionsController.text
          : 'Store pickup order - Customer pickup time: $_pickupTime',
      deliveryType: widget.deliveryOption == 'delivery'
          ? DeliveryType.delivery
          : DeliveryType.pickup,
      pickupTime: widget.deliveryOption == 'pickup' ? _pickupTime : null,
    );

    adminProvider.addOrder(order);

    // Only remove selected items from cart
    if (widget.selectedItems != null) {
      for (var item in widget.selectedItems!) {
        cartProvider.removeFromCart(item.product.id);
      }
    } else {
      cartProvider.clearCart();
    }

    // Save cart to database for this user
    if (user.email.isNotEmpty) {
      cartProvider.saveCartToDatabase(user.email);
    }

    setState(() {
      _currentStep = 2;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
  }
}
