import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/bouquet_size_card.dart';
import '../providers/cart_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';

class CustomBouquetBuilderScreen extends StatefulWidget {
  const CustomBouquetBuilderScreen({super.key});

  @override
  State<CustomBouquetBuilderScreen> createState() =>
      _CustomBouquetBuilderScreenState();
}

class _CustomBouquetBuilderScreenState
    extends State<CustomBouquetBuilderScreen> {
  final Map<String, Map<String, int>> _flowerQuantities = {};
  String? _selectedColorId; // Track selected bouquet color
  String? _selectedSize; // Track selected size (Small, Medium, Large)

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();

    final totalStems = _calculateTotalStems();
    final sizeInfo = _getBouquetSizeAndPrice(totalStems);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.9 * 255).round()),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFFCE4EC)),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/categories'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF3E5F5),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Build Your Custom Bouquet',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  'Create a personalized arrangement',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content - Step-based UI
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step 0: Choose Size (always visible)
                    _buildSizeSelection(),
                    const SizedBox(height: 24),

                    // Step 1: Choose Color Theme (appears after size selected)
                    if (_selectedSize != null) ...[
                      _buildColorThemeSelection(adminProvider),
                      const SizedBox(height: 24),
                    ],

                    // Step 2: Choose Flowers (appears after color selected)
                    if (_selectedColorId != null) ...[
                      _buildFlowerSelection(adminProvider),
                      const SizedBox(height: 24),
                    ],

                    // Selected Stems Summary (appears after color selection)
                    if (_selectedColorId != null) ...[
                      const SizedBox(height: 24),
                      _buildBouquetSummary(totalStems, sizeInfo),
                    ],
                  ],
                ),
              ),
            ),

            // Add to Cart Button (only after all steps completed)
            if (_selectedColorId != null && _flowerQuantities.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_canAddToCart(totalStems) &&
                                _selectedColorId != null &&
                                _flowerQuantities.isNotEmpty)
                            ? () => _addCustomBouquetToCart(
                                authProvider,
                                cartProvider,
                                adminProvider,
                                sizeInfo,
                              )
                            : null,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart),
                            SizedBox(width: 8),
                            Text('Add to Cart'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('💐', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Text(
              'Choose Your Bouquet Size',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final int columns = width >= 900 ? 3 : (width >= 600 ? 2 : 1);
            // Give cards more vertical space to avoid overflow on small devices
            final childAspect = width >= 900 ? 3.0 : (width >= 600 ? 2.6 : 2.6);

            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: childAspect,
              children: [
                BouquetSizeCard(
                  title: 'Small',
                  subtitle: 'Perfect intimate gesture with 1-2 flowers',
                  price: 25.99,
                  pillLabel: '1-2 flowers',
                  selected: _selectedSize == 'Small',
                  onTap: () => setState(() {
                    _selectedSize = 'Small';
                    _selectedColorId = null;
                    _flowerQuantities.clear();
                    debugPrint('Selected size set to Small');
                  }),
                ),
                BouquetSizeCard(
                  title: 'Medium',
                  subtitle: 'Beautiful arrangement with 6 flowers',
                  price: 45.99,
                  pillLabel: '6 flowers',
                  selected: _selectedSize == 'Medium',
                  onTap: () => setState(() {
                    _selectedSize = 'Medium';
                    _selectedColorId = null;
                    _flowerQuantities.clear();
                    debugPrint('Selected size set to Medium');
                  }),
                ),
                BouquetSizeCard(
                  title: 'Large',
                  subtitle: 'Stunning display with 12 flowers',
                  price: 85.99,
                  pillLabel: '12 flowers',
                  selected: _selectedSize == 'Large',
                  onTap: () => setState(() {
                    _selectedSize = 'Large';
                    _selectedColorId = null;
                    _flowerQuantities.clear();
                    debugPrint('Selected size set to Large');
                  }),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Old _buildSizeCard removed in favor of `BouquetSizeCard` widget

  Widget _buildColorThemeSelection(AdminProvider adminProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Bouquet Color Theme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'From: bouquet_colors',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Small debug/status row to help diagnose visibility issues
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Selected size: ${_selectedSize ?? 'none'} — colors: ${adminProvider.bouquetColors.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
            if (adminProvider.bouquetColors.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No color themes available',
                    style: TextStyle(color: AppTheme.mutedForeground),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: adminProvider.bouquetColors.length,
                itemBuilder: (context, index) {
                  try {
                    final color = adminProvider.bouquetColors[index];
                    final isSelected = _selectedColorId == color.id;
                    final hexColor = color.hexCode != null
                        ? int.tryParse(color.hexCode!.replaceFirst('#', '0xff'))
                        : null;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorId = color.id),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          // keep border width constant to avoid layout shifts
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFFE5E7EB),
                            width: 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: hexColor != null
                                ? Color(hexColor)
                                : Colors.grey[300],
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                color.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  // choose readable text color based on background luminance
                                  color: hexColor != null
                                      ? (Color(hexColor).computeLuminance() >
                                                0.6
                                            ? Colors.black
                                            : Colors.white)
                                      : Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2,
                                      color: Colors.black.withAlpha(90),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } catch (e, st) {
                    debugPrint('Error building color tile: $e\n$st');
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                        color: Colors.red[100],
                      ),
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowerSelection(AdminProvider adminProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌺', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Flower Stems',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'From: flowerTypes',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (adminProvider.flowers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text('🌸', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text(
                        'No flowers available',
                        style: TextStyle(color: AppTheme.mutedForeground),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ...adminProvider.flowers.map((flower) {
                    return _buildFlowerSelector(flower);
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowerSelector(dynamic flower) {
    final flowerId = flower.id;
    final flowerName = flower.name;
    final flowerImage = flower.image;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Flower Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(flowerImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Flower Name & Quantity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flowerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _flowerQuantities[flowerId]?.values
                              .fold(0, (a, b) => a + b)
                              .toString() ??
                          '0 stems',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity Control
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      iconSize: 16,
                      onPressed: () => _updateFlowerQuantity(flowerId, -1),
                    ),
                    Text(
                      (_flowerQuantities[flowerId]?.values.fold(
                                0,
                                (a, b) => a + b,
                              ) ??
                              0)
                          .toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      iconSize: 16,
                      onPressed: () => _updateFlowerQuantity(flowerId, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBouquetSummary(int totalStems, Map<String, dynamic> sizeInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('📋', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
                Text(
                  'Bouquet Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Color Theme:',
              _selectedColorId ?? 'Not selected',
            ),
            _buildSummaryRow('Total stems:', totalStems.toString()),
            _buildSummaryRow('Bouquet size:', sizeInfo['size'] as String),
            _buildSummaryRow(
              'Price:',
              '₱${(sizeInfo['price'] as double).toStringAsFixed(0)}',
              isPrice: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Professional arrangement: Included',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
            ),
            if (totalStems < AppConstants.minStemsForCustomBouquet)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 18)),
                    Expanded(
                      child: Text(
                        'Minimum ${AppConstants.minStemsForCustomBouquet} stems required. Add ${AppConstants.minStemsForCustomBouquet - totalStems} more stem${(AppConstants.minStemsForCustomBouquet - totalStems) != 1 ? 's' : ''} to complete your bouquet.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
                color: isPrice ? AppTheme.primary : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalStems() {
    int total = 0;
    _flowerQuantities.forEach((_, colors) {
      colors.forEach((_, quantity) {
        total += quantity;
      });
    });
    return total;
  }

  int? _requiredStemsForSelectedSize() {
    if (_selectedSize == 'Small') return 2;
    if (_selectedSize == 'Medium') return 6;
    if (_selectedSize == 'Large') return 12;
    return null;
  }

  bool _canAddToCart(int totalStems) {
    final req = _requiredStemsForSelectedSize();
    if (req != null) {
      return totalStems == req;
    }
    return totalStems >= AppConstants.minStemsForCustomBouquet;
  }

  void _updateFlowerQuantity(String flowerId, int change) {
    setState(() {
      _flowerQuantities.putIfAbsent(flowerId, () => {});
      const defaultColor = 'Mixed';
      final currentQuantity = _flowerQuantities[flowerId]![defaultColor] ?? 0;
      final newQuantity = (currentQuantity + change).clamp(0, 999);

      if (newQuantity == 0) {
        _flowerQuantities[flowerId]!.remove(defaultColor);
        if (_flowerQuantities[flowerId]!.isEmpty) {
          _flowerQuantities.remove(flowerId);
        }
      } else {
        _flowerQuantities[flowerId]![defaultColor] = newQuantity;
      }
    });
  }

  Map<String, dynamic> _getBouquetSizeAndPrice(int totalStems) {
    if (totalStems < 5) {
      return {'size': 'Custom', 'price': 0.0};
    } else if (totalStems < 15) {
      return {'size': 'Small', 'price': 250.0};
    } else if (totalStems < 25) {
      return {'size': 'Medium', 'price': 600.0};
    } else {
      return {'size': 'Large', 'price': 1200.0};
    }
  }

  void _addCustomBouquetToCart(
    AuthProvider authProvider,
    CartProvider cartProvider,
    AdminProvider adminProvider,
    Map<String, dynamic> sizeInfo,
  ) {
    final totalStems = _calculateTotalStems();
    final req = _requiredStemsForSelectedSize();
    if (req != null) {
      if (totalStems != req) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'For ${_selectedSize ?? 'the selected size'} you must select exactly $req stem${req != 1 ? 's' : ''}.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (totalStems < AppConstants.minStemsForCustomBouquet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum ${AppConstants.minStemsForCustomBouquet} stems required for a custom bouquet',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create description
    final flowerDetails = <String>[];
    _flowerQuantities.forEach((flowerId, colors) {
      final flower = adminProvider.flowers.firstWhere(
        (f) => f.id == flowerId,
        orElse: () => adminProvider.flowers.first,
      );
      colors.forEach((color, quantity) {
        flowerDetails.add('$quantity $color ${flower.name}');
      });
    });

    final customBouquet = Product(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Bouquet - ${sizeInfo['size']} ($totalStems stems)',
      price: sizeInfo['price'] as double,
      image:
          'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=800',
      category: 'Custom',
      description: 'Custom bouquet with ${flowerDetails.join(', ')}',
      isTodaysSpecial: false,
      isBestSeller: false,
      occasions: [],
    );

    cartProvider.addToCart(customBouquet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom ${sizeInfo['size']} bouquet added to cart!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear and navigate to cart
    setState(() {
      _flowerQuantities.clear();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      context.go('/cart');
    });
  }
}
