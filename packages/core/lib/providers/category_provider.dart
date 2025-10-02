import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/models/category.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  // TODO: Implement actual API call to get categories
  await Future.delayed(const Duration(seconds: 1));
  return [
    Category(
      id: 1,
      tenantId: 1,
      name: 'Appetizers',
      description: 'Start your meal with these delicious appetizers',
      status: CategoryStatus.active,
      image: null,
    ),
    Category(
      id: 2,
      tenantId: 1,
      name: 'Main Course',
      description: 'Our signature main dishes',
      status: CategoryStatus.active,
      image: null,
    ),
    Category(
      id: 3,
      tenantId: 1,
      name: 'Desserts',
      description: 'Sweet treats to end your meal',
      status: CategoryStatus.active,
      image: null,
    ),
    Category(
      id: 4,
      tenantId: 1,
      name: 'Beverages',
      description: 'Refreshing drinks and beverages',
      status: CategoryStatus.active,
      image: null,
    ),
  ];
});
