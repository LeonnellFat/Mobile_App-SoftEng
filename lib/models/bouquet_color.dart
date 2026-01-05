class BouquetColor {
  final String id;
  final String name;
  final String? hexCode;
  final String? description;

  BouquetColor({
    required this.id,
    required this.name,
    this.hexCode,
    this.description,
  });

  factory BouquetColor.fromMap(Map<String, dynamic> m) {
    return BouquetColor(
      id: m['id'] as String,
      name: m['name'] as String,
      hexCode: m['hex_code'] as String?,
      description: m['description'] as String?,
    );
  }

  @override
  String toString() => 'BouquetColor(id: $id, name: $name)';
}
