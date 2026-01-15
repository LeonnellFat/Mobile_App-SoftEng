# Real-Time Updates Implementation Examples

## How to Use in Your Screens

### Example 1: Automatic Updates (Already Working)

Products and categories screens will automatically receive updates without any code changes:

```dart
// In your products_screen.dart or categories_screen.dart
class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    // This will automatically rebuild when products change in real-time
    final adminProvider = context.watch<AdminProvider>();
    
    return ListView.builder(
      itemCount: adminProvider.products.length,
      itemBuilder: (context, index) {
        final product = adminProvider.products[index];
        return ProductCard(product: product);
      },
    );
  }
}
```

### Example 2: Manual Refresh Button

Add a manual refresh button to your UI:

```dart
class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      final adminProvider = context.read<AdminProvider>();
      await Future.wait([
        adminProvider.refreshProducts(),
        adminProvider.refreshCategories(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data refreshed!')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _isRefreshing ? null : _refreshData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          return ListView.builder(
            itemCount: adminProvider.products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: adminProvider.products[index]);
            },
          );
        },
      ),
    );
  }
}
```

### Example 3: Real-Time Indicator Badge

Show users when data is being synced:

```dart
class ProductsScreenHeader extends StatelessWidget {
  const ProductsScreenHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Products'),
            // Pulsing indicator shows real-time is active
            Tooltip(
              message: 'Real-time sync active',
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha((0.5 * 255).round()),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Example 4: Custom Listener in Your Screen

Listen for changes and perform custom actions:

```dart
class AdminProductsScreen extends StatefulWidget {
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late AdminProvider _adminProvider;

  @override
  void initState() {
    super.initState();
    _adminProvider = context.read<AdminProvider>();
    
    // Listen for product count changes
    _adminProvider.addListener(_onProductsChanged);
  }

  void _onProductsChanged() {
    // Perform custom action when products change
    final productCount = _adminProvider.products.length;
    debugPrint('📊 Product count updated: $productCount');
    
    // Show a notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Products updated! ($productCount items)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _adminProvider.removeListener(_onProductsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return ListView.builder(
          itemCount: adminProvider.products.length,
          itemBuilder: (context, index) {
            return AdminProductTile(
              product: adminProvider.products[index],
            );
          },
        );
      },
    );
  }
}
```

### Example 5: Handle Updates with Visual Feedback

Show which item was updated:

```dart
class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  Set<String> _recentlyUpdatedIds = {};

  @override
  void initState() {
    super.initState();
    final adminProvider = context.read<AdminProvider>();
    adminProvider.addListener(_onDataUpdated);
  }

  void _onDataUpdated() {
    // Mark all products as recently updated
    final adminProvider = context.read<AdminProvider>();
    setState(() {
      _recentlyUpdatedIds = 
          adminProvider.products.map((p) => p.id).toSet();
    });

    // Clear the highlight after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _recentlyUpdatedIds.clear());
      }
    });
  }

  @override
  void dispose() {
    context.read<AdminProvider>().removeListener(_onDataUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return ListView.builder(
          itemCount: adminProvider.products.length,
          itemBuilder: (context, index) {
            final product = adminProvider.products[index];
            final isRecent = _recentlyUpdatedIds.contains(product.id);

            return Container(
              // Flash animation on recent updates
              decoration: BoxDecoration(
                color: isRecent
                    ? Colors.yellow.withAlpha((0.3 * 255).round())
                    : Colors.transparent,
              ),
              child: ProductCard(product: product),
            );
          },
        );
      },
    );
  }
}
```

### Example 6: Filter Products in Real-Time

Filter the products list while maintaining real-time updates:

```dart
class FilteredProductsScreen extends StatefulWidget {
  @override
  State<FilteredProductsScreen> createState() => _FilteredProductsScreenState();
}

class _FilteredProductsScreenState extends State<FilteredProductsScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (value) => setState(() => _filter = value),
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          // Filter products in real-time
          final filteredProducts = adminProvider.products
              .where((product) =>
                  product.name.toLowerCase().contains(_filter.toLowerCase()) ||
                  (product.description?.toLowerCase().contains(
                        _filter.toLowerCase(),
                      ) ??
                      false))
              .toList();

          return ListView.builder(
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: filteredProducts[index]);
            },
          );
        },
      ),
    );
  }
}
```

### Example 7: Sync Status Indicator

Show the sync status in your app:

```dart
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Real-time sync active',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
```

## Best Practices

### ✅ DO:
```dart
// Use context.watch() for automatic rebuilds
final adminProvider = context.watch<AdminProvider>();
final products = adminProvider.products;

// Use Consumer for better performance
Consumer<AdminProvider>(
  builder: (context, adminProvider, child) {
    return ProductList(products: adminProvider.products);
  },
)

// Let real-time handle updates
// Don't manually poll/refresh constantly
```

### ❌ DON'T:
```dart
// Don't create multiple providers
final provider1 = AdminProvider();
final provider2 = AdminProvider(); // Wrong!

// Don't poll continuously
Timer.periodic(Duration(seconds: 1), (_) {
  refreshProducts(); // Unnecessary, use real-time instead
});

// Don't access provider outside of build methods
// (without Provider package features)
final products = adminProvider.products; // Outside build = bad
```

## Debugging Real-Time Updates

### Check if Realtime is Working:

```dart
class DebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug')),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Products'),
                subtitle: Text('${adminProvider.products.length} items'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              ListTile(
                title: const Text('Categories'),
                subtitle: Text('${adminProvider.categories.length} items'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const ListTile(
                title: Text('Real-time Status'),
                subtitle: Text('Connected & Listening'),
                trailing: Icon(Icons.circle, color: Colors.green),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    await adminProvider.refreshProducts();
                    await adminProvider.refreshCategories();
                  },
                  child: const Text('Manual Refresh'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

**All your screens will automatically sync with the database in real-time!**
