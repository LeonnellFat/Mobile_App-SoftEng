// Ignore deprecation warnings for `.execute()` usage from the supabase client.
// These are informational for now; consider updating to the newer API later.
// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/category.dart';
import '../models/bouquet_color.dart';
import '../models/flower_type.dart';
import '../models/order.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Image URL resolver — converts storage paths to public URLs
  static String resolveImageUrl(String? stored) {
    const fallback =
        'https://images.unsplash.com/photo-1599599810694-b5ac4dd13413?w=800';
    if (stored == null || stored.isEmpty) return fallback;
    if (stored.startsWith('http')) return stored;
    // If it's a storage path, try to get public URL from public bucket
    try {
      final url = _client.storage.from('public').getPublicUrl(stored);
      return url.isNotEmpty ? url : fallback;
    } catch (_) {
      return fallback;
    }
  }

  // Categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final data = await _client.from('categories').select().order('name');
      if (data == null) throw Exception('Supabase query returned null');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }

  // Category CRUD
  static Future<Map<String, dynamic>> insertCategory(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _client
          .from('categories')
          .insert(payload)
          .select()
          .maybeSingle();
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to insert category: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _client
          .from('categories')
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle();
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Products
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final res = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false)
          .execute();
      final data = res.data;
      if (data == null) throw Exception('Supabase query returned null: $res');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  // Typed product list (maps DB rows into app Product model)
  static Future<List<Product>> fetchProducts() async {
    try {
      // Fetch all products
      final productsData = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      if (productsData == null) return [];

      // Fetch all product-category relationships
      final categoriesData = await _client
          .from('product_categories')
          .select('product_id, categories(name)');

      // Create a map of product_id -> category_name
      final Map<String, String> productCategoryMap = {};
      if (categoriesData != null) {
        for (var item in categoriesData as List) {
          final productId = item['product_id'] as String?;
          final categoryObj = item['categories'] as Map<String, dynamic>?;
          if (productId != null && categoryObj != null) {
            final categoryName = categoryObj['name'] as String? ?? '';
            if (categoryName.isNotEmpty) {
              productCategoryMap[productId] = categoryName;
            }
          }
        }
      }

      return (productsData as List).map((m) {
        final mod = Map<String, dynamic>.from(m);

        // adapt DB types/keys to the app's Product.fromJson expectations
        // price may be stored as int in DB; the app model expects double
        final priceVal = mod['price'];
        mod['price'] = priceVal == null
            ? 0.0
            : (priceVal is int
                  ? priceVal.toDouble()
                  : (priceVal as num).toDouble());

        // Resolve image URL via storage or fallback
        mod['image'] = resolveImageUrl(mod['image'] as String?);

        // Get category from the map we created
        mod['category'] = productCategoryMap[mod['id']] ?? '';
        mod['description'] = mod['description'] ?? '';
        mod['isTodaysSpecial'] = mod['isTodaysSpecial'] ?? false;
        mod['isBestSeller'] = mod['isBestSeller'] ?? false;
        mod['occasions'] =
            (mod['occasions'] as List<dynamic>?)?.cast<String>() ?? [];
        return Product.fromJson(mod);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  // Products for a category (via product_categories link table)
  static Future<List<Map<String, dynamic>>> getProductsForCategory(
    String categoryId,
  ) async {
    try {
      final linkRes = await _client
          .from('product_categories')
          .select('product_id')
          .eq('category_id', categoryId)
          .execute();
      final linkData = linkRes.data as List?;
      final ids = linkData == null
          ? []
          : linkData.map((r) => r['product_id']).toList();
      if (ids.isEmpty) return [];
      final res = await _client
          .from('products')
          .select()
          .in_('id', ids)
          .execute();
      final data = res.data;
      return (data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to load products for category: $e');
    }
  }

  // Typed products for a category
  static Future<List<Product>> fetchProductsForCategory(
    String categoryId,
  ) async {
    try {
      // Fetch products for a specific category via the junction table
      final linkRes = await _client
          .from('product_categories')
          .select('product_id')
          .eq('category_id', categoryId)
          .execute();

      final linkData = linkRes.data as List?;
      final ids = linkData == null
          ? []
          : linkData.map((r) => r['product_id']).toList();

      if (ids.isEmpty) return [];

      // Fetch all products with those IDs
      final productsRes = await _client
          .from('products')
          .select()
          .in_('id', ids)
          .execute();

      final productsData = productsRes.data as List?;
      if (productsData == null) return [];

      // Fetch all product-category relationships to get category names
      final categoriesRes = await _client
          .from('product_categories')
          .select('product_id, categories(name)')
          .execute();

      final categoriesData = categoriesRes.data as List?;

      // Create a map of product_id -> category_name
      final Map<String, String> productCategoryMap = {};
      if (categoriesData != null) {
        for (var item in categoriesData) {
          final productId = item['product_id'] as String?;
          final categoryObj = item['categories'] as Map<String, dynamic>?;
          if (productId != null && categoryObj != null) {
            final categoryName = categoryObj['name'] as String? ?? '';
            if (categoryName.isNotEmpty) {
              productCategoryMap[productId] = categoryName;
            }
          }
        }
      }

      return productsData.map((m) {
        final mod = Map<String, dynamic>.from(m);

        final priceVal = mod['price'];
        mod['price'] = priceVal == null
            ? 0.0
            : (priceVal is int
                  ? priceVal.toDouble()
                  : (priceVal as num).toDouble());

        // Ensure image is a valid URL
        mod['image'] = resolveImageUrl(mod['image'] as String?);

        // Get category from the map we created
        mod['category'] = productCategoryMap[mod['id']] ?? '';
        mod['description'] = mod['description'] ?? '';
        mod['isTodaysSpecial'] = mod['isTodaysSpecial'] ?? false;
        mod['isBestSeller'] = mod['isBestSeller'] ?? false;
        mod['occasions'] =
            (mod['occasions'] as List<dynamic>?)?.cast<String>() ?? [];

        return Product.fromJson(mod);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load products for category: $e');
    }
  }

  // Bouquet colors
  static Future<List<Map<String, dynamic>>> getBouquetColors() async {
    try {
      final res = await _client
          .from('bouquet_colors')
          .select()
          .order('name')
          .execute();
      final data = res.data;
      if (data == null) throw Exception('Supabase query returned null: $res');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load bouquet colors: $e');
    }
  }

  // Typed bouquet colors
  static Future<List<BouquetColor>> fetchBouquetColors() async {
    try {
      final data = await _client.from('bouquet_colors').select().order('name');

      if (data == null) return [];

      return (data as List).map((m) {
        final mod = Map<String, dynamic>.from(m as Map<String, dynamic>);
        mod['image'] = resolveImageUrl(mod['image'] as String?);
        return BouquetColor.fromMap(mod);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching bouquet colors: $e');
      throw Exception('Failed to load bouquet colors: $e');
    }
  }

  // Get all orders (admin)
  static Future<List<Order>> getOrders() async {
    try {
      final data = await _client
          .from('orders')
          .select(
            '*, order_number, driver_id, profiles!orders_user_id_fkey(full_name, email, phone, address)',
          )
          .order('created_at', ascending: false);

      debugPrint('Raw orders data from Supabase: $data');

      if (data == null) {
        debugPrint('Orders data is null');
        return [];
      }

      final ordersList = List<Map<String, dynamic>>.from(data as List);
      debugPrint('Orders list length: ${ordersList.length}');

      return Future.wait(
        ordersList.map((o) async {
          try {
            debugPrint('Parsing order: $o');
            debugPrint('Order number from DB: ${o['order_number']}');

            // If there's a profiles object, merge it into the order data
            if (o['profiles'] != null) {
              final profile = o['profiles'] as Map<String, dynamic>;
              o['customer_name'] = profile['full_name'] ?? 'Unknown';
              o['customer_email'] = profile['email'] ?? '';
              o['customer_phone'] = profile['phone'] ?? '';
              o['customer_address'] = profile['address'] ?? '';
            }

            // Fetch order items with product details
            final itemsData = await _client
                .from('order_items')
                .select('*, products(id, name, price, image)')
                .eq('order_id', o['id']);

            if (itemsData != null && itemsData.isNotEmpty) {
              o['items'] = itemsData.map((item) {
                final product = item['products'] as Map<String, dynamic>?;
                return {
                  'product': {
                    'id': product?['id'] ?? '',
                    'name': product?['name'] ?? 'Unknown Product',
                    'price': ((product?['price'] ?? 0.0) as num).toDouble(),
                    'image': product?['image'] ?? '',
                    'category': '',
                    'description': '',
                    'isTodaysSpecial': false,
                    'isBestSeller': false,
                    'occasions': [],
                  },
                  'quantity': item['quantity'],
                };
              }).toList();
            } else {
              o['items'] = [];
            }

            final order = Order.fromJson(o);
            debugPrint(
              '✅ Parsed Order ID: ${order.id}, OrderNumber: ${order.orderNumber}, Driver ID: ${order.driverId}, Status: ${order.status}',
            );
            return order;
          } catch (e) {
            debugPrint('Error parsing individual order: $e');
            rethrow;
          }
        }),
      );
    } catch (e) {
      debugPrint('Error loading orders: $e');
      throw Exception('Failed to load orders: $e');
    }
  }

  /// Update order status in Supabase
  static Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? deliveryDate,
  }) async {
    try {
      // Get current user for debugging
      final currentUser = _client.auth.currentUser;
      debugPrint('👤 Current user ID: ${currentUser?.id}');
      debugPrint(
        '📝 Attempting to update order $orderId to status=$status, deliveryDate=$deliveryDate',
      );

      final updateData = {
        'status': status,
        if (deliveryDate != null) 'delivery_date': deliveryDate,
      };

      final response = await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .select();

      debugPrint(
        '✅ Order $orderId successfully updated to $status in Supabase',
      );
      debugPrint('Response: $response');
    } catch (e) {
      debugPrint('❌ Error updating order status: $e');
      debugPrint('Error type: ${e.runtimeType}');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Orders for a user
  static Future<List<Map<String, dynamic>>> getOrdersForUser(
    String userId,
  ) async {
    try {
      final res = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .execute();
      final data = res.data;
      return (data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to load orders for user: $e');
    }
  }

  // Typed categories
  static Future<List<Category>> fetchCategories() async {
    final maps = await getCategories();
    return maps.map((m) {
      final mod = Map<String, dynamic>.from(m);
      mod['image'] = resolveImageUrl(mod['image'] as String?);
      return Category.fromMap(mod);
    }).toList();
  }

  // Order items for an order
  static Future<List<Map<String, dynamic>>> getItemsForOrder(
    String orderId,
  ) async {
    try {
      final res = await _client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .execute();
      final data = res.data;
      return (data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to load items for order: $e');
    }
  }

  // Flower types CRUD
  static Future<List<Map<String, dynamic>>> getFlowerTypes() async {
    try {
      final res = await _client
          .from('flower_types')
          .select()
          .order('name')
          .execute();
      final data = res.data;
      if (data == null) throw Exception('Supabase query returned null: $res');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load flower types: $e');
    }
  }

  static Future<List<FlowerType>> fetchFlowerTypes() async {
    try {
      final data = await _client.from('flower_types').select().order('name');

      if (data == null) return [];

      return (data as List).map((m) {
        final mod = Map<String, dynamic>.from(m as Map<String, dynamic>);
        mod['image'] = resolveImageUrl(mod['image'] as String?);
        // Ensure colors is a list, default to empty if missing
        mod['colors'] = (mod['colors'] as List<dynamic>?)?.cast<String>() ?? [];
        return FlowerType.fromJson(mod);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching flower types: $e');
      throw Exception('Failed to load flower types: $e');
    }
  }

  static Future<Map<String, dynamic>> insertFlowerType(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _client
          .from('flower_types')
          .insert(payload)
          .select()
          .maybeSingle();
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to insert flower type: $e');
    }
  }

  static Future<Map<String, dynamic>> updateFlowerType(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _client
          .from('flower_types')
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle();
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to update flower type: $e');
    }
  }

  static Future<void> deleteFlowerType(String id) async {
    try {
      await _client.from('flower_types').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete flower type: $e');
    }
  }

  // Bouquet colors CRUD (insert/update/delete)
  static Future<Map<String, dynamic>> insertBouquetColor(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _client
          .from('bouquet_colors')
          .insert(payload)
          .select()
          .maybeSingle();
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to insert bouquet color: $e');
    }
  }

  static Future<Map<String, dynamic>> updateBouquetColor(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _client
          .from('bouquet_colors')
          .update(payload)
          .eq('id', id)
          .select()
          .maybeSingle();
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to update bouquet color: $e');
    }
  }

  static Future<void> deleteBouquetColor(String id) async {
    try {
      await _client.from('bouquet_colors').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete bouquet color: $e');
    }
  }

  // Cart Items
  static Future<List<Map<String, dynamic>>> fetchCartItemsForUser(
    String userId,
  ) async {
    try {
      final res = await _client
          .from('carts')
          .select('product_id, quantity')
          .eq('user_id', userId)
          .execute();

      final data = res.data as List?;
      if (data == null) return [];
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load cart items: $e');
    }
  }

  static Future<void> saveCartItemsForUser(
    String userId,
    List<Map<String, dynamic>> cartItems,
  ) async {
    try {
      // Clear existing cart items for this user
      await _client.from('carts').delete().eq('user_id', userId).execute();

      // Insert new cart items
      if (cartItems.isNotEmpty) {
        final itemsToInsert = cartItems.map((item) {
          return {
            'user_id': userId,
            'product_id': item['product_id'],
            'quantity': item['quantity'],
          };
        }).toList();

        await _client.from('carts').insert(itemsToInsert).execute();
      }
    } catch (e) {
      throw Exception('Failed to save cart items: $e');
    }
  }

  // User Profile
  static Future<Map<String, dynamic>?> fetchUserProfile(String email) async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle()
          .execute();

      final data = res.data as Map<String, dynamic>?;
      return data;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  static Future<void> updateUserProfile(
    String email,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client
          .from('profiles')
          .update(updates)
          .eq('email', email)
          .execute();
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // User Orders
  static Future<List<Map<String, dynamic>>> fetchUserOrders(
    String userId,
  ) async {
    try {
      final res = await _client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .execute();

      final data = res.data as List?;
      return data?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  // Get order items with product details
  static Future<List<Map<String, dynamic>>> getOrderItems(
    String orderId,
  ) async {
    try {
      final res = await _client
          .from('order_items')
          .select('id, order_id, product_id, quantity, price')
          .eq('order_id', orderId)
          .execute();

      final items = res.data as List? ?? [];

      // Fetch product details for each item
      List<Map<String, dynamic>> itemsWithProducts = [];
      for (var item in items) {
        final productRes = await _client
            .from('products')
            .select('id, name, price, image')
            .eq('id', item['product_id'])
            .maybeSingle()
            .execute();

        final product = productRes.data as Map<String, dynamic>?;
        final itemWithProduct = {
          ...item as Map<String, dynamic>,
          'name': product?['name'] ?? 'Unknown Product',
          'image': product?['image'],
        };
        itemsWithProducts.add(itemWithProduct);
      }

      return itemsWithProducts;
    } catch (e) {
      debugPrint('Error fetching order items: $e');
      return [];
    }
  }

  // Create order in Supabase
  static Future<void> createOrder(Order order) async {
    try {
      debugPrint('📝 Creating order in Supabase: ${order.id}');

      // Get current user from Supabase Auth
      final currentUser = _client.auth.currentUser;
      final userId = currentUser?.id ?? 'guest';

      debugPrint('👤 Current auth user ID: $userId');

      // Generate a proper UUID for the order (replace the ORD-timestamp with UUID)
      final orderId = _generateUUID();

      // Insert order - only include fields that exist in the orders table
      final orderData = {
        'id': orderId,
        'order_number': _generateOrderNumber(),
        'user_id': userId,
        'phone': order.customerPhone,
        'delivery_address': order.customerAddress,
        'total_amount': order.total.toInt(),
        'status': order.status.name,
        'date': order.orderDate,
        'delivery_date': order.deliveryDate,
        'delivery_option': order.deliveryType.name,
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('📊 Order data: $orderData');

      final response = await _client.from('orders').insert(orderData);
      debugPrint('✅ Order inserted. Response: $response');

      // Insert order items
      for (var item in order.items) {
        final itemData = {
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': (item.product.price as num).toInt(),
        };
        debugPrint('📦 Inserting order item: $itemData');
        await _client.from('order_items').insert(itemData);
      }

      debugPrint('✅ Order $orderId created successfully in Supabase');
    } catch (e) {
      debugPrint('❌ Error creating order in Supabase: $e');
      debugPrint('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Generate UUID v4
  static String _generateUUID() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));

    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${toHex(values[0])}${toHex(values[1])}'
        '${toHex(values[2])}${toHex(values[3])}'
        '-${toHex(values[4])}${toHex(values[5])}'
        '-${toHex(values[6])}${toHex(values[7])}'
        '-${toHex(values[8])}${toHex(values[9])}'
        '-${toHex(values[10])}${toHex(values[11])}'
        '${toHex(values[12])}${toHex(values[13])}'
        '${toHex(values[14])}${toHex(values[15])}';
  }

  // Generate order number
  static String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'ORD-${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  /// Real-time listeners for products and categories
  static Future<void> subscribeToProductChanges(
    Function(List<Product>) onDataChanged,
  ) async {
    try {
      _client.channel('products:*').on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'products'),
        (payload, [ref]) {
          debugPrint('📡 Product change detected: ${payload['eventType']}');
          fetchProducts()
              .then((products) {
                onDataChanged(products);
              })
              .catchError((e) {
                debugPrint('❌ Error handling product change: $e');
              });
        },
      ).subscribe();
      debugPrint('✅ Subscribed to product changes');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to product changes: $e');
    }
  }

  static Future<void> subscribeToCategoryChanges(
    Function(List<Category>) onDataChanged,
  ) async {
    try {
      _client.channel('categories:*').on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'categories'),
        (payload, [ref]) {
          debugPrint('📡 Category change detected: ${payload['eventType']}');
          fetchCategories()
              .then((categories) {
                onDataChanged(categories);
              })
              .catchError((e) {
                debugPrint('❌ Error handling category change: $e');
              });
        },
      ).subscribe();
      debugPrint('✅ Subscribed to category changes');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to category changes: $e');
    }
  }

  static Future<void> unsubscribeFromProducts(dynamic subscription) async {
    try {
      await _client.channel('products:*').unsubscribe();
      debugPrint('✅ Unsubscribed from product changes');
    } catch (e) {
      debugPrint('⚠️ Error unsubscribing from products: $e');
    }
  }

  static Future<void> unsubscribeFromCategories(dynamic subscription) async {
    try {
      await _client.channel('categories:*').unsubscribe();
      debugPrint('✅ Unsubscribed from category changes');
    } catch (e) {
      debugPrint('⚠️ Error unsubscribing from categories: $e');
    }
  }

  static Future<void> subscribeToOrderChanges(
    Function(List<Order>) onDataChanged,
  ) async {
    try {
      _client.channel('orders:*').on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(event: '*', schema: 'public', table: 'orders'),
        (payload, [ref]) {
          debugPrint('📡 Order change detected: ${payload['eventType']}');
          getOrders()
              .then((orders) {
                onDataChanged(orders);
              })
              .catchError((e) {
                debugPrint('❌ Error handling order change: $e');
              });
        },
      ).subscribe();
      debugPrint('✅ Subscribed to order changes');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to order changes: $e');
    }
  }

  static Future<void> unsubscribeFromOrders(dynamic subscription) async {
    try {
      await _client.channel('orders:*').unsubscribe();
      debugPrint('✅ Unsubscribed from order changes');
    } catch (e) {
      debugPrint('⚠️ Error unsubscribing from orders: $e');
    }
  }
}
