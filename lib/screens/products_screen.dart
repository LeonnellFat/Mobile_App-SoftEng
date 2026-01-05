import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../models/product.dart';
import '../providers/admin_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../services/supabase_service.dart';
import '../utils/responsive_helper.dart';

class ProductsScreen extends StatefulWidget {
  final String? selectedCategory;
  final VoidCallback? onNavigateToCart;
  final void Function(Product)? onProductClick;

  const ProductsScreen({
    super.key,
    this.selectedCategory,
    this.onNavigateToCart,
    this.onProductClick,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  int _currentPage = 1;
  final int _itemsPerPage = 8;
  late Future<List<Product>>? _categoryProductsFuture;
  bool _isCategoryMode = false;
  String? _selectedCategoryId;

  // Cache for category products to avoid re-fetching
  final Map<String, List<Product>> _categoryProductsCache = {};

  @override
  void initState() {
    super.initState();

    // Check if this is a category ID or category name
    if (widget.selectedCategory != null &&
        widget.selectedCategory!.isNotEmpty) {
      // Category IDs from Supabase are typically UUIDs or contain hyphens
      // Category names are typically short words
      _isCategoryMode =
          widget.selectedCategory!.length > 10 ||
          widget.selectedCategory!.contains('-');

      if (_isCategoryMode) {
        // This is a category ID - fetch products for it
        _selectedCategoryId = widget.selectedCategory!;
        _categoryProductsFuture = SupabaseService.fetchProductsForCategory(
          widget.selectedCategory!,
        );
      } else {
        // This is a category name
        _selectedFilter = widget.selectedCategory!;
        _categoryProductsFuture = null;
      }
    } else {
      _categoryProductsFuture = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchOrFilterChange() {
    setState(() {
      _currentPage = 1;
    });
  }

  void _onCategoryFilterSelected(String categoryName) {
    final adminProvider = context.read<AdminProvider>();

    if (categoryName == 'All') {
      // Reset to all products
      setState(() {
        _selectedFilter = 'All';
        _currentPage = 1;
        _isCategoryMode = false;
        _selectedCategoryId = null;
        _categoryProductsFuture = null;
      });
    } else {
      // Find the category ID for this category name
      final category = adminProvider.categories.firstWhere(
        (c) => c.name == categoryName,
        orElse: () => adminProvider.categories.first,
      );

      // Check if we have cached products for this category
      if (_categoryProductsCache.containsKey(category.id)) {
        // Use cached products - no loading animation
        setState(() {
          _selectedFilter = categoryName;
          _selectedCategoryId = category.id;
          _isCategoryMode = true;
          // Create a future that returns the cached data immediately
          _categoryProductsFuture = Future.value(
            _categoryProductsCache[category.id]!,
          );
          _currentPage = 1;
        });
      } else {
        // Fetch products for this category and cache them
        setState(() {
          _selectedFilter = categoryName;
          _selectedCategoryId = category.id;
          _isCategoryMode = true;
          _categoryProductsFuture =
              SupabaseService.fetchProductsForCategory(category.id).then((
                products,
              ) {
                // Cache the results for future use
                _categoryProductsCache[category.id] = products;
                return products;
              });
          _currentPage = 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    // If we have a category ID future, use it to fetch products
    if (_isCategoryMode && _categoryProductsFuture != null) {
      return FutureBuilder<List<Product>>(
        future: _categoryProductsFuture!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(height: 16),
                      Text('Error loading products: ${snapshot.error}'),
                    ],
                  ),
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];
          return _buildProductsScreen(context, products, cartProvider);
        },
      );
    } else {
      // Show all products or filter by category name
      final products = adminProvider.products;
      return _buildProductsScreen(context, products, cartProvider);
    }
  }

  Widget _buildProductsScreen(
    BuildContext context,
    List<Product> products,
    CartProvider cartProvider,
  ) {
    final adminProvider = context.read<AdminProvider>();

    // Set the filter category name if in category mode and not yet set
    if (_isCategoryMode &&
        _selectedCategoryId != null &&
        _selectedFilter == 'All') {
      final category = adminProvider.categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => adminProvider.categories.first,
      );
      // Update the filter to match the category name for display only
      _selectedFilter = category.name;
    }

    // Filter products based on search query
    // When in category mode, all products are already from the selected category
    // so we only need to filter by search query
    final filteredProducts = products.where((p) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);

      // Only apply category filter when NOT in category mode
      if (_isCategoryMode) {
        return matchesSearch;
      }

      final matchesCategory =
          _selectedFilter == 'All' || p.category == _selectedFilter;
      return matchesCategory && matchesSearch;
    }).toList();

    final totalPages = (filteredProducts.isEmpty
        ? 1
        : (filteredProducts.length / _itemsPerPage).ceil());
    final startIndex = ((_currentPage - 1) * _itemsPerPage).clamp(
      0,
      filteredProducts.length,
    );
    final endIndex = (_currentPage * _itemsPerPage).clamp(
      0,
      filteredProducts.length,
    );
    final paginatedProducts = filteredProducts.isEmpty
        ? <Product>[]
        : filteredProducts.sublist(startIndex, endIndex);

    // Get categories from AdminProvider instead of from products
    final categories = <String>[
      'All',
      ...adminProvider.categories.map((c) => c.name),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.95),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Our Products',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Discover our flower collection',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 8),
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.shopping_cart_outlined,
                                    ),
                                    onPressed: widget.onNavigateToCart,
                                  ),
                                  if (cartProvider.getTotalItems() > 0)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          cartProvider
                                              .getTotalItems()
                                              .toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => _onSearchOrFilterChange(),
                        decoration: InputDecoration(
                          hintText: 'Search flowers, bouquets...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final category = categories[i];
                            final isSelected = _selectedFilter == category;
                            // Disable category switching when viewing a specific category
                            final isDisabled =
                                _isCategoryMode && category != 'All';
                            return ChoiceChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFF3E5F5),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected
                                    ? AppTheme.primary
                                    : const Color(0xFFE0E0E0),
                                width: isSelected ? 2 : 1,
                              ),
                              showCheckmark: true,
                              checkmarkColor: AppTheme.primary,
                              onSelected: isDisabled
                                  ? null
                                  : (_) => _onCategoryFilterSelected(category),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedFilter == 'All'
                              ? 'All Products'
                              : _selectedFilter,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${filteredProducts.length} ${filteredProducts.length == 1 ? 'product' : 'products'} found',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final paginationHeight = totalPages > 1 ? 72.0 : 0.0;
                          final gridHeight =
                              (constraints.maxHeight - paginationHeight).clamp(
                                0.0,
                                double.infinity,
                              );

                          if (filteredProducts.isEmpty) {
                            return Center(
                              child: Text(
                                'No products found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            );
                          }

                          return Column(
                            children: [
                              SizedBox(
                                height: gridHeight,
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            ResponsiveHelper.getGridColumns(
                                              context,
                                            ),
                                        childAspectRatio:
                                            ResponsiveHelper.getChildAspectRatio(
                                              context,
                                            ),
                                        crossAxisSpacing:
                                            ResponsiveHelper.getResponsiveSpacing(
                                              context,
                                              small: 10,
                                              medium: 12,
                                              large: 12,
                                            ),
                                        mainAxisSpacing:
                                            ResponsiveHelper.getResponsiveSpacing(
                                              context,
                                              small: 10,
                                              medium: 12,
                                              large: 12,
                                            ),
                                      ),
                                  itemCount: paginatedProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = paginatedProducts[index];
                                    return ProductCard(
                                      product: product,
                                      onTap: () {
                                        // Navigate to product detail with GoRouter
                                        context.go(
                                          '/product/${product.id}',
                                          extra: product,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              if (totalPages > 1)
                                SizedBox(
                                  height: paginationHeight,
                                  child: Center(
                                    child: _buildPagination(totalPages),
                                  ),
                                ),
                            ],
                          );
                        },
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

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_outlined),
          onPressed: _currentPage > 1
              ? () => setState(
                  () => _currentPage = (_currentPage - 1).clamp(1, totalPages),
                )
              : null,
        ),
        for (var i = 1; i <= totalPages; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                side: BorderSide(
                  color: i == _currentPage
                      ? AppTheme.primary
                      : Colors.grey.shade200,
                ),
                backgroundColor: i == _currentPage
                    ? AppTheme.primary.withAlpha((0.08 * 255).round())
                    : null,
              ),
              onPressed: () => setState(() => _currentPage = i),
              child: Text(
                '$i',
                style: TextStyle(
                  color: i == _currentPage
                      ? AppTheme.primary
                      : AppTheme.mutedForeground,
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right_outlined),
          onPressed: _currentPage < totalPages
              ? () => setState(
                  () => _currentPage = (_currentPage + 1).clamp(1, totalPages),
                )
              : null,
        ),
      ],
    );
  }
}
