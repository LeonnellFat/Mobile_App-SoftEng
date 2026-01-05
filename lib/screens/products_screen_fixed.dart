import 'package:flutter/widgets.dart';

/// Minimal placeholder widget to replace a previously corrupted file. This
/// prevents analyzer cascades while we stabilize the real implementation.
class ProductsScreenFixed extends StatelessWidget {
  const ProductsScreenFixed({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
