// import 'package:freezed_annotation/freezed_annotation.dart';
import 'product.dart';

// part 'cart_item.freezed.dart';
// part 'cart_item.g.dart';

// @freezed
class CartItem {
  // const factory CartItem({
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.modifiers,
    this.notes,
    this.specialInstructions,
  });

  final int id;
  final Product product;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<CartItemModifier>? modifiers;
  final String? notes;
  final String? specialInstructions;

  // factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int,
      product: Product.fromMap(map['product'] as Map<String, dynamic>),
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      modifiers: map['modifiers'] != null
          ? (map['modifiers'] as List<dynamic>)
              .map((modifier) => CartItemModifier.fromMap(modifier as Map<String, dynamic>))
              .toList()
          : null,
      notes: map['notes'] as String?,
      specialInstructions: map['special_instructions'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product': product.toMap(),
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'modifiers': modifiers?.map((modifier) => modifier.toMap()).toList(),
      'notes': notes,
      'special_instructions': specialInstructions,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  CartItem copyWith({
    int? id,
    Product? product,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<CartItemModifier>? modifiers,
    String? notes,
    String? specialInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      modifiers: modifiers ?? this.modifiers,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

// @freezed
class CartItemModifier {
  // const factory CartItemModifier({
  const CartItemModifier({
    required this.id,
    required this.name,
    required this.price,
    required this.type,
  });

  final int id;
  final String name;
  final double price;
  final String type;

  // factory CartItemModifier.fromJson(Map<String, dynamic> json) => _$CartItemModifierFromJson(json);

  factory CartItemModifier.fromMap(Map<String, dynamic> map) {
    return CartItemModifier(
      id: map['id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'type': type,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  CartItemModifier copyWith({
    int? id,
    String? name,
    double? price,
    String? type,
  }) {
    return CartItemModifier(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      type: type ?? this.type,
    );
  }
}
