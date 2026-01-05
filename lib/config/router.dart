import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/products_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/driver_screen.dart';
import '../screens/custom_bouquet_builder_screen.dart';
import '../models/product.dart';
import '../widgets/navigation_bar.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // User/Customer routes (with bottom nav)
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          String activeTab;
          final loc = state.location;
          // Determine which tab is active based on current route
          // Note: Check custom-bouquet before categories since custom-bouquet also starts with /c
          if (loc.startsWith('/custom-bouquet')) {
            activeTab = 'categories';
          } else if (loc.startsWith('/categories')) {
            activeTab = 'categories';
          } else if (loc.startsWith('/products')) {
            activeTab = 'products';
          } else if (loc.startsWith('/profile')) {
            activeTab = 'profile';
          } else {
            activeTab = 'home';
          }

          return Scaffold(
            body: child,
            bottomNavigationBar: AppNavigationBar(
              activeTab: activeTab,
              onTabChange: (tab) {
                switch (tab) {
                  case 'home':
                    context.go('/');
                    break;
                  case 'products':
                    context.go('/products');
                    break;
                  case 'categories':
                    context.go('/categories');
                    break;
                  case 'profile':
                    context.go('/profile');
                    break;
                }
              },
            ),
          );
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder: (context, state) {
              final uri = Uri.parse(state.location);
              final category = uri.queryParameters['category'];
              return ProductsScreen(
                selectedCategory: category,
                onNavigateToCart: () => context.go('/cart'),
              );
            },
          ),
          GoRoute(
            path: '/product/:id',
            builder: (context, state) {
              final product = state.extra as Product;
              return ProductDetailScreen(
                product: product,
                onNavigateToCart: () => context.go('/cart'),
              );
            },
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => CategoriesScreen(
              onNavigate: (tab) {
                if (tab == 'cart') {
                  context.go('/cart');
                  return;
                }
                if (tab == 'custom_bouquet') {
                  context.go('/custom-bouquet');
                  return;
                }
              },
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/custom-bouquet',
            builder: (context, state) => const CustomBouquetBuilderScreen(),
          ),
        ],
      ),

      // Admin routes (NO bottom nav)
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),

      // Driver route
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverScreen(),
      ),
    ],
  );
}
