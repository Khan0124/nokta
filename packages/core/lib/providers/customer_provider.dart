import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/models/customer_address.dart';

final customerAddressesProvider = FutureProvider<List<CustomerAddress>>((ref) async {
  // TODO: Implement actual API call to get customer addresses
  // For now, return mock data
  await Future.delayed(const Duration(seconds: 1));
  return [
    CustomerAddress(
      id: '1',
      title: 'Home',
      address: '123 Main St, City, Country',
      latitude: 40.7128,
      longitude: -74.0060,
      isDefault: true,
    ),
    CustomerAddress(
      id: '2',
      title: 'Work',
      address: '456 Business Ave, City, Country',
      latitude: 40.7589,
      longitude: -73.9851,
      isDefault: false,
    ),
  ];
});

final customerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Implement actual API call to get customer data
  await Future.delayed(const Duration(seconds: 1));
  return {
    'id': '1',
    'name': 'John Doe',
    'email': 'john@example.com',
    'phone': '+1234567890',
  };
});
