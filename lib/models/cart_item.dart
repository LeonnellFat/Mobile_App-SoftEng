import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  bool isSelected;

  CartItem({required this.product, this.quantity = 1, this.isSelected = true});

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(product: product, quantity: quantity);
  }

  double get totalPrice => product.price * quantity;

  bool get selected => isSelected;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      isSelected: json['isSelected'] as bool? ?? true,
    );
  }

  CartItem copyWith({Product? product, int? quantity, bool? isSelected}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
