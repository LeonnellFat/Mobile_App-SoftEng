class Occasion {
  final String id;
  final String name;
  final String image;
  final String icon;
  final String description;

  Occasion({
    required this.id,
    required this.name,
    required this.image,
    this.icon = '🎉',
    this.description = '',
  });

  factory Occasion.fromJson(Map<String, dynamic> json) => Occasion(
    id: json['id'] as String,
    name: json['name'] as String,
    image: json['image'] as String,
    icon: json['icon'] as String? ?? '🎉',
    description: json['description'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'icon': icon,
    'description': description,
  };
}
