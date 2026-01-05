class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String category;
  final String description;
  final bool isTodaysSpecial;
  final bool isBestSeller;
  final List<String> occasions;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.description,
    this.isTodaysSpecial = false,
    this.isBestSeller = false,
    this.occasions = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      isTodaysSpecial: json['isTodaysSpecial'] as bool? ?? false,
      isBestSeller: json['isBestSeller'] as bool? ?? false,
      occasions: (json['occasions'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'category': category,
      'description': description,
      'isTodaysSpecial': isTodaysSpecial,
      'isBestSeller': isBestSeller,
      'occasions': occasions,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? image,
    String? category,
    String? description,
    bool? isTodaysSpecial,
    bool? isBestSeller,
    List<String>? occasions,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      description: description ?? this.description,
      isTodaysSpecial: isTodaysSpecial ?? this.isTodaysSpecial,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      occasions: occasions ?? this.occasions,
    );
  }
}
