import 'package:flutter/material.dart';
import '../config/theme.dart';

class BouquetSizeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double price;
  final bool selected;
  final VoidCallback? onTap;
  final String? pillLabel;

  const BouquetSizeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    this.selected = false,
    this.onTap,
    this.pillLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 128),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // keep border width constant to avoid layout shifting when selected
            border: Border.all(
              color: selected ? AppTheme.primary : const Color(0xFFEAEAEA),
              width: 1.0,
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
              if (selected)
                BoxShadow(
                  color: AppTheme.primary.withAlpha((0.12 * 255).round()),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (pillLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pillLabel!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              // Price column
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC407A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Base price',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
