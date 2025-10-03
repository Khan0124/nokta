import 'package:intl/intl.dart';

enum DriverTaskStatus {
  assigned,
  accepted,
  pickedUp,
  enRoute,
  delivered,
  failed,
  cancelled,
}

enum DriverPaymentMethod {
  cash,
  card,
  wallet,
  bankTransfer,
}

class DriverTask {
  const DriverTask({
    required this.id,
    required this.driverId,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.dropoffAddress,
    required this.latitude,
    required this.longitude,
    required this.amountDue,
    required this.currency,
    required this.status,
    required this.requiresCollection,
    required this.createdAt,
    this.pickedAt,
    this.enRouteAt,
    this.deliveredAt,
    this.cancelledAt,
    this.failedAt,
    this.paymentMethod,
    this.collectedAmount,
    this.notes,
    this.routeSnapshotId,
  });

  final String id;
  final String driverId;
  final int orderId;
  final String customerName;
  final String customerPhone;
  final String dropoffAddress;
  final double latitude;
  final double longitude;
  final double amountDue;
  final String currency;
  final DriverTaskStatus status;
  final bool requiresCollection;
  final DateTime createdAt;
  final DateTime? pickedAt;
  final DateTime? enRouteAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? failedAt;
  final DriverPaymentMethod? paymentMethod;
  final double? collectedAmount;
  final String? notes;
  final String? routeSnapshotId;

  DriverTask copyWith({
    DriverTaskStatus? status,
    DateTime? pickedAt,
    DateTime? enRouteAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? failedAt,
    DriverPaymentMethod? paymentMethod,
    double? collectedAmount,
    String? notes,
    String? routeSnapshotId,
  }) {
    return DriverTask(
      id: id,
      driverId: driverId,
      orderId: orderId,
      customerName: customerName,
      customerPhone: customerPhone,
      dropoffAddress: dropoffAddress,
      latitude: latitude,
      longitude: longitude,
      amountDue: amountDue,
      currency: currency,
      status: status ?? this.status,
      requiresCollection: requiresCollection,
      createdAt: createdAt,
      pickedAt: pickedAt ?? this.pickedAt,
      enRouteAt: enRouteAt ?? this.enRouteAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      failedAt: failedAt ?? this.failedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      collectedAmount: collectedAmount ?? this.collectedAmount,
      notes: notes ?? this.notes,
      routeSnapshotId: routeSnapshotId ?? this.routeSnapshotId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'order_id': orderId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'dropoff_address': dropoffAddress,
      'latitude': latitude,
      'longitude': longitude,
      'amount_due': amountDue,
      'currency': currency,
      'status': status.name,
      'requires_collection': requiresCollection ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'picked_at': pickedAt?.toIso8601String(),
      'en_route_at': enRouteAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'failed_at': failedAt?.toIso8601String(),
      'payment_method': paymentMethod?.name,
      'collected_amount': collectedAmount,
      'notes': notes,
      'route_snapshot_id': routeSnapshotId,
    };
  }

  factory DriverTask.fromMap(Map<String, dynamic> map) {
    return DriverTask(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      orderId: map['order_id'] as int,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String,
      dropoffAddress: map['dropoff_address'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      amountDue: (map['amount_due'] as num).toDouble(),
      currency: map['currency'] as String,
      status: DriverTaskStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => DriverTaskStatus.assigned,
      ),
      requiresCollection: (map['requires_collection'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      pickedAt: map['picked_at'] != null
          ? DateTime.tryParse(map['picked_at'] as String)
          : null,
      enRouteAt: map['en_route_at'] != null
          ? DateTime.tryParse(map['en_route_at'] as String)
          : null,
      deliveredAt: map['delivered_at'] != null
          ? DateTime.tryParse(map['delivered_at'] as String)
          : null,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.tryParse(map['cancelled_at'] as String)
          : null,
      failedAt: map['failed_at'] != null
          ? DateTime.tryParse(map['failed_at'] as String)
          : null,
      paymentMethod: map['payment_method'] != null
          ? DriverPaymentMethod.values.firstWhere(
              (value) => value.name == map['payment_method'],
              orElse: () => DriverPaymentMethod.cash,
            )
          : null,
      collectedAmount: map['collected_amount'] != null
          ? (map['collected_amount'] as num).toDouble()
          : null,
      notes: map['notes'] as String?,
      routeSnapshotId: map['route_snapshot_id'] as String?,
    );
  }

  String get formattedAmountDue {
    final formatter = NumberFormat.currency(name: currency);
    return formatter.format(amountDue);
  }
}
