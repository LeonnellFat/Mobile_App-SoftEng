import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/flower_type.dart';
import '../models/bouquet_decor_color.dart';
import '../models/bouquet_color.dart';
import '../models/occasion.dart';
import '../models/category.dart' as cat;
import '../services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  final List<Product> _products = [];
  final List<FlowerType> _flowers = [];
  final List<BouquetDecorColor> _bouquetDecorColors = [];
  final List<BouquetColor> _bouquetColors = [];
  final List<Occasion> _occasions = [];
  final List<cat.Category> _categories = [];
  final Map<String, int> _productCountByCategory = {};

  List<Order> get orders => List.unmodifiable(_orders);
  List<Product> get products => List.unmodifiable(_products);
  List<FlowerType> get flowers => List.unmodifiable(_flowers);
  List<BouquetDecorColor> get bouquetDecorColors =>
      List.unmodifiable(_bouquetDecorColors);
  List<BouquetColor> get bouquetColors => List.unmodifiable(_bouquetColors);
  List<Occasion> get occasions => List.unmodifiable(_occasions);
  List<cat.Category> get categories => List.unmodifiable(_categories);

  AdminProvider();

  /// Load products (and optionally other admin data) from Supabase service.
  /// Call this once after Supabase.initialize() to populate the in-memory lists.
  Future<void> loadProductsFromSupabase() async {
    // Intentionally left as a no-op placeholder so main can populate the
    // provider after fetching from SupabaseService. This avoids circular
    // import issues and keeps the provider testable.
    return Future.value();
  }

  /// Replace current products list with [products] and notify listeners.
  void setProducts(List<Product> products) {
    _products
      ..clear()
      ..addAll(products);
    notifyListeners();
  }

  /// Replace current categories list with [categories] and notify listeners.
  void setCategories(List<cat.Category> categories) {
    _categories
      ..clear()
      ..addAll(categories);
    notifyListeners();
  }

  /// Replace current flowers list with [flowers] and notify listeners.
  void setFlowers(List<FlowerType> flowers) {
    _flowers
      ..clear()
      ..addAll(flowers);
    notifyListeners();
  }

  void addOrder(Order order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
      notifyListeners();
    }
  }

  Product addProduct(Product product) {
    final newProduct = product.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _products.add(newProduct);
    notifyListeners();
    return newProduct;
  }

  void updateProduct(String productId, Product updates) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = updates;
      notifyListeners();
    }
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  FlowerType addFlower(FlowerType flower) {
    final newFlower = flower.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _flowers.add(newFlower);
    notifyListeners();
    return newFlower;
  }

  void updateFlower(String flowerId, FlowerType updates) {
    final index = _flowers.indexWhere((f) => f.id == flowerId);
    if (index != -1) {
      _flowers[index] = updates;
      notifyListeners();
    }
  }

  void deleteFlower(String flowerId) {
    _flowers.removeWhere((f) => f.id == flowerId);
    notifyListeners();
  }

  BouquetDecorColor addBouquetDecorColor(BouquetDecorColor decorColor) {
    final newColor = decorColor.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _bouquetDecorColors.add(newColor);
    notifyListeners();
    return newColor;
  }

  void updateBouquetDecorColor(String decorId, BouquetDecorColor updates) {
    final index = _bouquetDecorColors.indexWhere((d) => d.id == decorId);
    if (index != -1) {
      _bouquetDecorColors[index] = updates;
      notifyListeners();
    }
  }

  void deleteBouquetDecorColor(String decorId) {
    _bouquetDecorColors.removeWhere((d) => d.id == decorId);
    notifyListeners();
  }

  /// BouquetColor CRUD operations (Supabase bouquet_colors table)
  void setBouquetColors(List<BouquetColor> colors) {
    _bouquetColors
      ..clear()
      ..addAll(colors);
    notifyListeners();
  }

  /// Replace current orders list with [orders] and notify listeners.
  void setOrders(List<Order> orders) {
    _orders
      ..clear()
      ..addAll(orders);
    notifyListeners();
  }

  BouquetColor addBouquetColor(BouquetColor color) {
    final newColor = BouquetColor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: color.name,
      hexCode: color.hexCode,
      description: color.description,
    );
    _bouquetColors.add(newColor);
    notifyListeners();
    return newColor;
  }

  void updateBouquetColor(String colorId, BouquetColor updates) {
    final index = _bouquetColors.indexWhere((c) => c.id == colorId);
    if (index != -1) {
      _bouquetColors[index] = updates;
      notifyListeners();
    }
  }

  void deleteBouquetColor(String colorId) {
    _bouquetColors.removeWhere((c) => c.id == colorId);
    notifyListeners();
  }

  void addOccasion(Occasion occasion) {
    final newOccasion = Occasion.fromJson({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': occasion.name,
      'image': occasion.image,
      'icon': occasion.icon,
      'description': occasion.description,
    });
    _occasions.add(newOccasion);
    notifyListeners();
  }

  void deleteOccasion(String occasionId) {
    _occasions.removeWhere((o) => o.id == occasionId);
    notifyListeners();
  }

  /// Get product count for a category (cached)
  int getProductCountForCategory(String categoryId) {
    return _productCountByCategory[categoryId] ?? 0;
  }

  /// Fetch and cache product count for a category from Supabase
  Future<int> fetchProductCountForCategory(String categoryId) async {
    try {
      final products = await SupabaseService.fetchProductsForCategory(
        categoryId,
      );
      final count = products.length;
      _productCountByCategory[categoryId] = count;
      notifyListeners();
      return count;
    } catch (e) {
      debugPrint('Error fetching product count for category: $e');
      return 0;
    }
  }

  Map<String, dynamic> getOrderStats() {
    final today = DateTime.now();
    final todayOrders = _orders.where((order) {
      final orderDate = DateTime.parse(order.orderDate);
      return orderDate.year == today.year &&
          orderDate.month == today.month &&
          orderDate.day == today.day;
    }).length;

    final pendingOrders = _orders
        .where(
          (order) =>
              order.status == OrderStatus.pending ||
              order.status == OrderStatus.confirmed,
        )
        .length;

    final totalRevenue = _orders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.total);

    return {
      'totalOrders': _orders.length,
      'pendingOrders': pendingOrders,
      'totalRevenue': totalRevenue,
      'todayOrders': todayOrders,
    };
  }
}
