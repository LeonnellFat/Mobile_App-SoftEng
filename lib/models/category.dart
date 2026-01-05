class Category {
  final String id;
  final String name;
  final String? description;
  final String? image;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
  });

  factory Category.fromMap(Map<String, dynamic> m) {
    return Category(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      image: m['image'] as String?,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
