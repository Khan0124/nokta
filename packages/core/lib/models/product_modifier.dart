// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'product_modifier.freezed.dart';
// part 'product_modifier.g.dart';

enum ModifierType {
  size,
  addon,
  extra,
  option,
  topping,
  sauce,
  spice,
}

// @freezed
class ProductModifier {
  // const factory ProductModifier({
  const ProductModifier({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.type,
    this.description,
    this.isRequired,
    this.maxQuantity,
    this.minQuantity,
    this.sortOrder,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int productId;
  final String name;
  final double price;
  final ModifierType type;
  final String? description;
  final bool? isRequired;
  final int? maxQuantity;
  final int? minQuantity;
  final int? sortOrder;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // factory ProductModifier.fromJson(Map<String, dynamic> json) => _$ProductModifierFromJson(json);

  factory ProductModifier.fromMap(Map<String, dynamic> map) {
    return ProductModifier(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      type: ModifierType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ModifierType.option,
      ),
      description: map['description'] as String?,
      isRequired: map['is_required'] as bool?,
      maxQuantity: map['max_quantity'] as int?,
      minQuantity: map['min_quantity'] as int?,
      sortOrder: map['sort_order'] as int?,
      isActive: map['is_active'] as bool?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'type': type.name,
      'description': description,
      'is_required': isRequired,
      'max_quantity': maxQuantity,
      'min_quantity': minQuantity,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  ProductModifier copyWith({
    int? id,
    int? productId,
    String? name,
    double? price,
    ModifierType? type,
    String? description,
    bool? isRequired,
    int? maxQuantity,
    int? minQuantity,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModifier(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      type: type ?? this.type,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
