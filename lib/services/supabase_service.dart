// Ignore deprecation warnings for `.execute()` usage from the supabase client.
// These are informational for now; consider updating to the newer API later.
// ignore_for_file: deprecated_member_use

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
            '*, profiles!orders_user_id_fkey(full_name, email, phone, address)',
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
    String userEmail,
  ) async {
    try {
      final res = await _client
          .from('orders')
          .select()
          .eq('customer_email', userEmail)
          .order('created_at', ascending: false)
          .execute();

      final data = res.data as List?;
      return data?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }
}
