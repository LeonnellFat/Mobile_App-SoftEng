import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'config/router.dart';
import 'config/theme.dart';
import 'providers/admin_provider.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read Supabase credentials from constants
  const supabaseUrl = AppConstants.supabaseUrl;
  const supabaseAnonKey = AppConstants.supabaseAnonKey;

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  // Debug info: print which Supabase credentials the app will use.
  // We avoid printing the full anon key to keep logs safer; just indicate if it's set.
  debugPrint('Supabase URL: $supabaseUrl');
  debugPrint('Supabase anon key present: ${supabaseAnonKey.isNotEmpty}');

  // Create AdminProvider and pre-load products from Supabase so the UI has
  // data on startup. This avoids showing empty states until a user action.
  final adminProvider = AdminProvider();
  try {
    debugPrint('🔄 Starting product fetch from Supabase...');
    final products = await SupabaseService.fetchProducts();
    debugPrint(
      '✅ Successfully loaded ${products.length} products from Supabase.',
    );
    adminProvider.setProducts(products);

    debugPrint('🔄 Starting category fetch from Supabase...');
    final categories = await SupabaseService.fetchCategories();
    debugPrint(
      '✅ Successfully loaded ${categories.length} categories from Supabase.',
    );
    adminProvider.setCategories(categories);

    debugPrint('🔄 Starting flower types fetch from Supabase...');
    try {
      final flowerTypes = await SupabaseService.fetchFlowerTypes();
      debugPrint(
        '✅ Successfully loaded ${flowerTypes.length} flower types from Supabase.',
      );
      adminProvider.setFlowers(flowerTypes);
    } catch (e) {
      debugPrint('⚠️ Error loading flower types: $e');
    }

    debugPrint('🔄 Starting bouquet colors fetch from Supabase...');
    try {
      final bouquetColors = await SupabaseService.fetchBouquetColors();
      debugPrint(
        '✅ Successfully loaded ${bouquetColors.length} bouquet colors from Supabase.',
      );
      adminProvider.setBouquetColors(bouquetColors);
    } catch (e) {
      debugPrint('⚠️ Error loading bouquet colors: $e');
    }

    debugPrint('🔄 Starting orders fetch from Supabase...');
    try {
      final orders = await SupabaseService.getOrders();
      debugPrint(
        '✅ Successfully loaded ${orders.length} orders from Supabase.',
      );
      adminProvider.setOrders(orders);
    } catch (e) {
      debugPrint('⚠️ Error loading orders: $e');
    }
  } catch (e) {
    debugPrint('❌ Failed to load data from Supabase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => adminProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Jean's Flower Shop",
      routerConfig: AppRouter.router,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
