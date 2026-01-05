import 'package:flutter/material.dart';

class BouquetDecorColor {
  final String id;
  final String name;
  final Color color;
  final double additionalCost;

  BouquetDecorColor({
    required this.id,
    required this.name,
    required this.color,
    this.additionalCost = 0.0,
  });

  factory BouquetDecorColor.fromJson(Map<String, dynamic> json) {
    return BouquetDecorColor(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(
        int.parse(json['color'].substring(1), radix: 16) + 0xFF000000,
      ),
      additionalCost: (json['additionalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': '#${color.toARGB32().toRadixString(16).substring(2)}',
      'additionalCost': additionalCost,
    };
  }

  BouquetDecorColor copyWith({
    String? id,
    String? name,
    Color? color,
    double? additionalCost,
  }) {
    return BouquetDecorColor(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      additionalCost: additionalCost ?? this.additionalCost,
    );
  }
}
