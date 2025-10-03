enum OrderTrackingStage {
  placed,
  confirmed,
  preparing,
  ready,
  driverAssigned,
  onTheWay,
  delivered,
  cancelled,
}

class OrderTrackingUpdate {
  const OrderTrackingUpdate({
    required this.orderId,
    required this.stage,
    required this.timestamp,
    this.message,
    this.etaMinutes,
    this.progress,
    this.driverLatitude,
    this.driverLongitude,
  });

  final int orderId;
  final OrderTrackingStage stage;
  final DateTime timestamp;
  final String? message;
  final int? etaMinutes;
  final double? progress;
  final double? driverLatitude;
  final double? driverLongitude;

  OrderTrackingUpdate copyWith({
    int? orderId,
    OrderTrackingStage? stage,
    DateTime? timestamp,
    String? message,
    int? etaMinutes,
    double? progress,
    double? driverLatitude,
    double? driverLongitude,
  }) {
    return OrderTrackingUpdate(
      orderId: orderId ?? this.orderId,
      stage: stage ?? this.stage,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      progress: progress ?? this.progress,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
    );
  }
}
