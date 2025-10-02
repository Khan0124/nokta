import 'package:flutter_riverpod/flutter_riverpod.dart';

final restaurantProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Implement actual API call to get restaurant data
  await Future.delayed(const Duration(seconds: 1));
  return {
    'id': 'rest_123',
    'name': 'Delicious Restaurant',
    'cuisine': 'International',
    'rating': 4.5,
    'reviewCount': 150,
    'hours': '9:00 AM - 10:00 PM',
    'address': '123 Main Street, City, Country',
    'phone': '+1234567890',
    'deliveryTime': '30-45',
    'categories': ['Appetizers', 'Main Course', 'Desserts', 'Beverages'],
    'products': [
      {
        'id': 'prod_1',
        'name': 'Margherita Pizza',
        'description': 'Fresh tomato sauce with mozzarella cheese',
        'price': 12.99,
        'category': 'Main Course',
        'image': null,
      },
      {
        'id': 'prod_2',
        'name': 'Caesar Salad',
        'description': 'Fresh romaine lettuce with Caesar dressing',
        'price': 8.99,
        'category': 'Appetizers',
        'image': null,
      },
      {
        'id': 'prod_3',
        'name': 'Chocolate Cake',
        'description': 'Rich chocolate cake with vanilla ice cream',
        'price': 6.99,
        'category': 'Desserts',
        'image': null,
      },
    ],
  };
});
