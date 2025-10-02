import 'package:flutter_riverpod/flutter_riverpod.dart';

final driverLocationProvider = StreamProvider<Map<String, dynamic>>((ref) {
  // TODO: Implement actual driver location tracking
  return Stream.periodic(const Duration(seconds: 3), (i) => {
    'driverId': 'driver_123',
    'latitude': 40.7128 + (i * 0.001),
    'longitude': -74.0060 + (i * 0.001),
    'timestamp': DateTime.now().toIso8601String(),
    'status': 'active',
  });
});

final orderProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Implement actual order data fetching
  await Future.delayed(const Duration(seconds: 1));
  return {
    'id': 'order_123',
    'status': 'preparing',
    'estimatedDelivery': DateTime.now().add(const Duration(minutes: 30)),
    'driver': {
      'id': 'driver_123',
      'name': 'John Driver',
      'phone': '+1234567890',
      'vehicle': 'Toyota Camry - ABC123',
    },
  };
});
