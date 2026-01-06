import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../config/constants.dart';
import '../services/supabase_service.dart';

class DeliveryAddress {
  final String name;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String? specialInstructions;

  DeliveryAddress({
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    this.specialInstructions,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];
  DeliveryAddress? _deliveryAddress;
  bool _showGuestModal = false;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  DeliveryAddress? get deliveryAddress => _deliveryAddress;
  bool get showGuestModal => _showGuestModal;

  void setShowGuestModal(bool show) {
    _showGuestModal = show;
    notifyListeners();
  }

  void setDeliveryAddress(DeliveryAddress address) {
    _deliveryAddress = address;
    notifyListeners();
  }

  bool addToCart(Product product) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].quantity++;
    } else {
      _cartItems.add(CartItem.fromProduct(product));
    }

    notifyListeners();
    return true;
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity == 0) {
      removeFromCart(productId);
    } else {
      final itemIndex = _cartItems.indexWhere(
        (item) => item.product.id == productId,
      );
      if (itemIndex != -1) {
        _cartItems[itemIndex].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  int getTotalItems() {
    return _cartItems.fold(0, (total, item) => total + item.quantity);
  }

  double getSubtotal() {
    return _cartItems.fold(
      0.0,
      (total, item) => total + (item.product.price * item.quantity),
    );
  }

  double getTotal({required bool isDelivery}) {
    final subtotal = getSubtotal();
    final deliveryFee = isDelivery ? AppConstants.deliveryFee : 0.0;
    final tax = subtotal * AppConstants.taxRate;
    return subtotal + deliveryFee + tax;
  }

  double getTax() {
    return getSubtotal() * AppConstants.taxRate;
  }

  double getDeliveryFee(bool isDelivery) {
    return isDelivery ? AppConstants.deliveryFee : 0.0;
  }

  // Selection methods
  void toggleItemSelection(String productId) {
    final itemIndex = _cartItems.indexWhere(
      (item) => item.product.id == productId,
    );
    if (itemIndex != -1) {
      _cartItems[itemIndex].isSelected = !_cartItems[itemIndex].isSelected;
      notifyListeners();
    }
  }

  void selectAllItems() {
    for (var item in _cartItems) {
      item.isSelected = true;
    }
    notifyListeners();
  }

  void deselectAllItems() {
    for (var item in _cartItems) {
      item.isSelected = false;
    }
    notifyListeners();
  }

  bool areAllItemsSelected() {
    if (_cartItems.isEmpty) return false;
    return _cartItems.every((item) => item.isSelected);
  }

  int getSelectedItemCount() {
    return _cartItems.where((item) => item.isSelected).length;
  }

  double getSelectedSubtotal() {
    return _cartItems
        .where((item) => item.isSelected)
        .fold(
          0.0,
          (total, item) => total + (item.product.price * item.quantity),
        );
  }

  List<CartItem> getSelectedItems() {
    return _cartItems.where((item) => item.isSelected).toList();
  }

  Future<void> loadCartFromDatabase(
    String userId,
    List<Product> allProducts,
  ) async {
    try {
      debugPrint('🔄 Loading cart items from database for user: $userId');
      final cartData = await SupabaseService.fetchCartItemsForUser(userId);

      _cartItems.clear();

      for (var item in cartData) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;

        // Find the product from the provided list
        try {
          final product = allProducts.firstWhere(
            (p) => p.id == productId,
            orElse: () => throw Exception('Product not found'),
          );
          _cartItems.add(CartItem(product: product, quantity: quantity));
        } catch (e) {
          debugPrint('⚠️ Product $productId not found in products list');
        }
      }

      debugPrint('✅ Loaded ${_cartItems.length} cart items from database');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading cart from database: $e');
    }
  }

  /// Save cart items to Supabase for a logged-in user
  Future<void> saveCartToDatabase(String userId) async {
    try {
      debugPrint('🔄 Saving cart items to database for user: $userId');
      final cartData = _cartItems.map((item) {
        return {'product_id': item.product.id, 'quantity': item.quantity};
      }).toList();

      await SupabaseService.saveCartItemsForUser(userId, cartData);
      debugPrint('✅ Saved ${_cartItems.length} cart items to database');
    } catch (e) {
      debugPrint('❌ Error saving cart to database: $e');
    }
  }
}
