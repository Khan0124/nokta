// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'product.freezed.dart';
// part 'product.g.dart';

enum ProductStatus {
  active,
  inactive,
  outOfStock,
  discontinued,
}

enum ProductType {
  food,
  beverage,
  dessert,
  side,
  modifier,
  combo,
}

// @freezed
class Product {
  // const factory Product({
  const Product({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.status,
    required this.type,
    this.image,
    this.ingredients,
    this.allergens,
    this.nutritionalInfo,
    this.preparationTime,
    this.isVegetarian,
    this.isVegan,
    this.isGlutenFree,
    this.isHalal,
    this.isKosher,
    this.isFeatured,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int tenantId;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final ProductStatus status;
  final ProductType type;
  final String? image;
  final List<String>? ingredients;
  final List<String>? allergens;
  final Map<String, dynamic>? nutritionalInfo;
  final int? preparationTime;
  final bool? isVegetarian;
  final bool? isVegan;
  final bool? isGlutenFree;
  final bool? isHalal;
  final bool? isKosher;
  final bool? isFeatured;
  final int? sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      tenantId: map['tenant_id'] as int,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProductStatus.active,
      ),
      type: ProductType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ProductType.food,
      ),
      image: map['image'] as String?,
      ingredients: map['ingredients'] != null
          ? (map['ingredients'] as List<dynamic>).cast<String>()
          : null,
      allergens: map['allergens'] != null
          ? (map['allergens'] as List<dynamic>).cast<String>()
          : null,
      nutritionalInfo: map['nutritional_info'] as Map<String, dynamic>?,
      preparationTime: map['preparation_time'] as int?,
      isVegetarian: map['is_vegetarian'] as bool?,
      isVegan: map['is_vegan'] as bool?,
      isGlutenFree: map['is_gluten_free'] as bool?,
      isHalal: map['is_halal'] as bool?,
      isKosher: map['is_kosher'] as bool?,
      isFeatured: map['is_featured'] as bool?,
      sortOrder: map['sort_order'] as int?,
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
      'tenant_id': tenantId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'status': status.name,
      'type': type.name,
      'image': image,
      'ingredients': ingredients,
      'allergens': allergens,
      'nutritional_info': nutritionalInfo,
      'preparation_time': preparationTime,
      'is_vegetarian': isVegetarian,
      'is_vegan': isVegan,
      'is_gluten_free': isGlutenFree,
      'is_halal': isHalal,
      'is_kosher': isKosher,
      'is_featured': isFeatured,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Product copyWith({
    int? id,
    int? tenantId,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    ProductStatus? status,
    ProductType? type,
    String? image,
    List<String>? ingredients,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    int? preparationTime,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    bool? isHalal,
    bool? isKosher,
    bool? isFeatured,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      type: type ?? this.type,
      image: image ?? this.image,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      preparationTime: preparationTime ?? this.preparationTime,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isHalal: isHalal ?? this.isHalal,
      isKosher: isKosher ?? this.isKosher,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
