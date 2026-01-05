class Flower {
  final String id;
  final String name;
  final String image;
  final List<String> colors;

  Flower({
    required this.id,
    required this.name,
    required this.image,
    this.colors = const [],
  });

  factory Flower.fromJson(Map<String, dynamic> json) => Flower(
    id: json['id'] as String,
    name: json['name'] as String,
    image: json['image'] as String,
    colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'colors': colors,
  };
}
