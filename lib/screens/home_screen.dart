import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/admin_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../utils/responsive_helper.dart';
// removed loading_indicator import — show empty state when no products

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final cartProvider = context.watch<CartProvider>();
    final products = adminProvider.products;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: products.isEmpty
              ? _buildEmptyState(context)
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(context, cartProvider),
                    ),

                    // Search Bar
                    SliverToBoxAdapter(child: _buildSearchBar(context)),

                    // Featured Product
                    if (products.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildFeaturedProduct(
                          context,
                          products.first,
                          cartProvider,
                        ),
                      ),

                    // Best Sellers Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveHelper.getResponsiveHorizontalPadding(
                            context,
                          ),
                          32,
                          ResponsiveHelper.getResponsiveHorizontalPadding(
                            context,
                          ),
                          16,
                        ),
                        child: Text(
                          '🏆 Best Sellers',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              20,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // Product Grid
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveHelper.getResponsiveHorizontalPadding(
                              context,
                            ),
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveHelper.getGridColumns(
                            context,
                          ),
                          childAspectRatio:
                              ResponsiveHelper.getChildAspectRatio(context),
                          crossAxisSpacing:
                              ResponsiveHelper.getResponsiveSpacing(
                                context,
                                small: 12,
                                medium: 14,
                                large: 16,
                              ),
                          mainAxisSpacing:
                              ResponsiveHelper.getResponsiveSpacing(
                                context,
                                small: 12,
                                medium: 14,
                                large: 16,
                              ),
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              context.push(
                                '/product/${product.id}',
                                extra: product,
                              );
                            },
                            onAddToCart: () {
                              cartProvider.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} added to cart',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppTheme.primary,
                                ),
                              );
                            },
                          );
                        }, childCount: products.length),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                      ), // Bottom padding for nav bar
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartProvider cartProvider) {
    final horizontalPadding = ResponsiveHelper.getResponsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha((0.3 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_florist,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jean's Flower Shop",
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      20,
                      maxSize: 28,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Beautiful blooms, delivered fresh',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      12,
                      maxSize: 14,
                    ),
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: cartProvider.getTotalItems() > 0,
              label: Text('${cartProvider.getTotalItems()}'),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            const Text(
              'No products available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are currently no products. Check back later or visit Products.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/products'),
              child: const Text('Browse Products'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveHorizontalPadding(
      context,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for flowers, occasions...',
            prefixIcon: const Icon(
              Icons.search,
              color: AppTheme.mutedForeground,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedProduct(
    BuildContext context,
    product,
    CartProvider cartProvider,
  ) {
    final horizontalPadding = ResponsiveHelper.getResponsiveHorizontalPadding(
      context,
    );
    return Container(
      margin: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: product.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.error_outline,
                          color: AppTheme.destructive,
                          size: 48,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha((0.7 * 255).round()),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "✨ Today's Special",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            12,
                            maxSize: 14,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          20,
                          maxSize: 28,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₱${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              24,
                              maxSize: 32,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            cartProvider.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text('Order Now'),
                        ),
                      ],
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
}
