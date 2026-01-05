class FlowerType {
  final String id;
  final String name;
  final String image;
  final List<String> colors;

  FlowerType({
    required this.id,
    required this.name,
    required this.image,
    required this.colors,
  });

  factory FlowerType.fromJson(Map<String, dynamic> json) {
    return FlowerType(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      colors: (json['colors'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'colors': colors,
    };
  }

  FlowerType copyWith({
    String? id,
    String? name,
    String? image,
    List<String>? colors,
  }) {
    return FlowerType(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      colors: colors ?? this.colors,
    );
  }
}
