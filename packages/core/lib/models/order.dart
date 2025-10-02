// import 'package:freezed_annotation/freezed_annotation.dart';

// part 'order.freezed.dart';
// part 'order.g.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

enum OrderType {
  dineIn,
  takeaway,
  delivery,
  online,
}

enum PaymentMethod {
  cash,
  card,
  mobilePayment,
  bankTransfer,
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

// @freezed
class Order {
  // const factory Order({
  const Order({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.customerId,
    required this.orderType,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    this.paymentMethod,
    this.paymentStatus,
    this.driverId,
    this.deliveryAddress,
    this.scheduledTime,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int tenantId;
  final int branchId;
  final int customerId;
  final OrderType orderType;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? paymentStatus;
  final int? driverId;
  final String? deliveryAddress;
  final DateTime? scheduledTime;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int,
      tenantId: map['tenant_id'] as int,
      branchId: map['branch_id'] as int,
      customerId: map['customer_id'] as int,
      orderType: OrderType.values.firstWhere(
        (e) => e.name == map['order_type'],
        orElse: () => OrderType.dineIn,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      deliveryFee: (map['delivery_fee'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == map['payment_method'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      paymentStatus: map['payment_status'] != null
          ? PaymentStatus.values.firstWhere(
              (e) => e.name == map['payment_status'],
              orElse: () => PaymentStatus.pending,
            )
          : null,
      driverId: map['driver_id'] as int?,
      deliveryAddress: map['delivery_address'] as String?,
      scheduledTime: map['scheduled_time'] != null
          ? DateTime.parse(map['scheduled_time'] as String)
          : null,
      notes: map['notes'] as String?,
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
      'branch_id': branchId,
      'customer_id': customerId,
      'order_type': orderType.name,
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': paymentMethod?.name,
      'payment_status': paymentStatus?.name,
      'driver_id': driverId,
      'delivery_address': deliveryAddress,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  Order copyWith({
    int? id,
    int? tenantId,
    int? branchId,
    int? customerId,
    OrderType? orderType,
    OrderStatus? status,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? total,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int? driverId,
    String? deliveryAddress,
    DateTime? scheduledTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      driverId: driverId ?? this.driverId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// @freezed
class OrderItem {
  // const factory OrderItem({
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.modifiers,
    this.notes,
  });

  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<OrderItemModifier>? modifiers;
  final String? notes;

  // factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      modifiers: map['modifiers'] != null
          ? (map['modifiers'] as List<dynamic>)
              .map((modifier) => OrderItemModifier.fromMap(modifier as Map<String, dynamic>))
              .toList()
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'modifiers': modifiers?.map((modifier) => modifier.toMap()).toList(),
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  OrderItem copyWith({
    int? id,
    int? orderId,
    int? productId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<OrderItemModifier>? modifiers,
    String? notes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      modifiers: modifiers ?? this.modifiers,
      notes: notes ?? this.notes,
    );
  }
}

// @freezed
class OrderItemModifier {
  // const factory OrderItemModifier({
  const OrderItemModifier({
    required this.id,
    required this.orderItemId,
    required this.modifierId,
    required this.name,
    required this.price,
  });

  final int id;
  final int orderItemId;
  final int modifierId;
  final String name;
  final double price;

  // factory OrderItemModifier.fromJson(Map<String, dynamic> json) => _$OrderItemModifierFromJson(json);

  factory OrderItemModifier.fromMap(Map<String, dynamic> map) {
    return OrderItemModifier(
      id: map['id'] as int,
      orderItemId: map['order_item_id'] as int,
      modifierId: map['modifier_id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_item_id': orderItemId,
      'modifier_id': modifierId,
      'name': name,
      'price': price,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  OrderItemModifier copyWith({
    int? id,
    int? orderItemId,
    int? modifierId,
    String? name,
    double? price,
  }) {
    return OrderItemModifier(
      id: id ?? this.id,
      orderItemId: orderItemId ?? this.orderItemId,
      modifierId: modifierId ?? this.modifierId,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}