import 'package:flutter/material.dart';
import '../config/theme.dart';

class AdminNavigationBar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabChange;

  const AdminNavigationBar({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard},
      {'id': 'orders', 'label': 'Orders', 'icon': Icons.receipt_long},
      {'id': 'products', 'label': 'Products', 'icon': Icons.shopping_bag},
      {'id': 'flowers', 'label': 'FlowerTypes', 'icon': Icons.local_florist},
      {'id': 'categories', 'label': 'Categories', 'icon': Icons.category},
      {'id': 'bouquet_colors', 'label': 'Colors', 'icon': Icons.palette},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: tabs.map((tab) {
            final isActive = activeTab == tab['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTabChange(tab['id'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withAlpha((0.1 * 255).round())
                          : Colors.transparent,
                      border: Border.all(
                        color: isActive ? AppTheme.primary : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          color: isActive ? AppTheme.primary : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
