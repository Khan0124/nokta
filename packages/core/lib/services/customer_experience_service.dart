import 'dart:async';
import 'dart:math';

import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/customer_loyalty.dart';
import '../models/driver_route_point.dart';
import '../models/order.dart';
import '../models/order_tracking_update.dart';
import '../models/product.dart';
import '../models/restaurant_summary.dart';

class CustomerExperienceService {
  CustomerExperienceService({DateTime? now}) : _now = now ?? DateTime.now() {
    _seedDemoData();
  }

  final DateTime _now;
  final _random = Random(17);

  late final List<Category> _categories;
  late final List<RestaurantSummary> _restaurants;
  late final Map<int, RestaurantDetail> _restaurantDetails;
  late final Map<int, Order> _orders;
  late final Map<int, List<OrderTrackingUpdate>> _orderTimelines;
  late final Map<int, List<DriverRoutePoint>> _driverRoutes;
  late LoyaltySummary _loyaltySummary;

  void _seedDemoData() {
    _categories = [
      Category(
        id: 1,
        tenantId: 1,
        name: 'Starters',
        description: 'Small bites to kick off your meal',
        status: CategoryStatus.active,
        sortOrder: 1,
      ),
      Category(
        id: 2,
        tenantId: 1,
        name: 'Mains',
        description: 'Signature mains and family favourites',
        status: CategoryStatus.active,
        sortOrder: 2,
      ),
      Category(
        id: 3,
        tenantId: 1,
        name: 'Desserts',
        description: 'Sweet endings and seasonal treats',
        status: CategoryStatus.active,
        sortOrder: 3,
      ),
      Category(
        id: 4,
        tenantId: 1,
        name: 'Beverages',
        description: 'Fresh juices, mocktails, and coffee',
        status: CategoryStatus.active,
        sortOrder: 4,
      ),
    ];

    List<Product> _buildProducts() {
      int id = 1;
      Product create({
        required int categoryId,
        required String name,
        required String description,
        required double price,
        ProductType type = ProductType.food,
        bool isFeatured = false,
        List<String>? allergens,
      }) {
        return Product(
          id: id++,
          tenantId: 1,
          categoryId: categoryId,
          name: name,
          description: description,
          price: price,
          status: ProductStatus.active,
          type: type,
          isFeatured: isFeatured,
          allergens: allergens,
          image: null,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now,
        );
      }

      return [
        create(
          categoryId: 1,
          name: 'Crispy Halloumi Bites',
          description: 'Golden halloumi with local honey drizzle',
          price: 21.0,
          isFeatured: true,
        ),
        create(
          categoryId: 1,
          name: 'Smoked Baba Ghanouj',
          description: 'Fire-roasted eggplant with tahini and pomegranate',
          price: 18.5,
        ),
        create(
          categoryId: 2,
          name: 'Signature Musakhan Wrap',
          description: 'Sumac chicken with caramelised onions and saj bread',
          price: 34.0,
          isFeatured: true,
        ),
        create(
          categoryId: 2,
          name: 'Charcoal Lamb Kabsa',
          description: 'Slow cooked lamb over aromatic saffron rice',
          price: 42.0,
        ),
        create(
          categoryId: 3,
          name: 'Pistachio Basbousa',
          description: 'Warm semolina cake, cardamom syrup, clotted cream',
          price: 16.0,
          type: ProductType.dessert,
        ),
        create(
          categoryId: 4,
          name: 'Mint Lemon Cooler',
          description: 'Fresh mint, citrus, sparkling water',
          price: 14.0,
          type: ProductType.beverage,
        ),
      ];
    }

    final products = _buildProducts();

    RestaurantSummary summaryFor({
      required int id,
      required String name,
      required String cuisine,
      required double rating,
      required int ratingCount,
      required int etaMin,
      required int etaMax,
      required double deliveryFee,
      required bool isFavorite,
      required bool isOpen,
      required double distanceKm,
      required String heroImage,
      required List<String> tags,
    }) {
      return RestaurantSummary(
        id: id,
        name: name,
        cuisine: cuisine,
        rating: rating,
        ratingCount: ratingCount,
        estimatedDeliveryMinutes: RangeValues(etaMin, etaMax),
        deliveryFee: deliveryFee,
        isFavorite: isFavorite,
        isOpen: isOpen,
        distanceKm: distanceKm,
        heroImage: heroImage,
        tags: tags,
      );
    }

    _restaurants = [
      summaryFor(
        id: 1,
        name: 'Nokta Kitchen',
        cuisine: 'Modern Levantine',
        rating: 4.8,
        ratingCount: 982,
        etaMin: 25,
        etaMax: 35,
        deliveryFee: 9.0,
        isFavorite: true,
        isOpen: true,
        distanceKm: 1.2,
        heroImage: 'assets/images/restaurants/nokta_kitchen.jpg',
        tags: const ['family', 'organic', 'grill'],
      ),
      summaryFor(
        id: 2,
        name: 'Dunes Burger Lab',
        cuisine: 'Smash Burgers',
        rating: 4.6,
        ratingCount: 641,
        etaMin: 20,
        etaMax: 30,
        deliveryFee: 6.0,
        isFavorite: false,
        isOpen: true,
        distanceKm: 2.4,
        heroImage: 'assets/images/restaurants/dunes_burger.jpg',
        tags: const ['comfort', 'late-night'],
      ),
      summaryFor(
        id: 3,
        name: 'Saffron Garden',
        cuisine: 'Indian Fusion',
        rating: 4.7,
        ratingCount: 743,
        etaMin: 35,
        etaMax: 45,
        deliveryFee: 11.0,
        isFavorite: true,
        isOpen: false,
        distanceKm: 3.1,
        heroImage: 'assets/images/restaurants/saffron_garden.jpg',
        tags: const ['spicy', 'vegetarian'],
      ),
      summaryFor(
        id: 4,
        name: 'Coastal Catch',
        cuisine: 'Seafood Grill',
        rating: 4.5,
        ratingCount: 321,
        etaMin: 30,
        etaMax: 40,
        deliveryFee: 12.0,
        isFavorite: false,
        isOpen: true,
        distanceKm: 4.5,
        heroImage: 'assets/images/restaurants/coastal_catch.jpg',
        tags: const ['premium', 'seasonal'],
      ),
    ];

    _restaurantDetails = {
      for (final summary in _restaurants)
        summary.id: RestaurantDetail(
          summary: summary,
          about:
              'Celebrating regional ingredients with modern techniques, ${summary.name} is a local favourite for curated delivery experiences.',
          sections: _buildSections(products),
          address: 'King Fahd Road, Riyadh',
          phone: '+966 55 123 4567',
          openingHours: '11:00 - 00:00',
          supportsPickup: true,
          supportsDelivery: true,
          averageSpend: 68.0,
          paymentMethods: const ['cash', 'card', 'mada'],
          chefNotes: const [
            'We toast spices in small batches for every order.',
            'Ask for the seasonal chef special available on weekends.',
          ],
        ),
    };

    final orderItems = [
      OrderItem(
        id: 1,
        orderId: 1001,
        productId: products.first.id,
        quantity: 2,
        unitPrice: products.first.price,
        totalPrice: products.first.price * 2,
        notes: products.first.name,
      ),
      OrderItem(
        id: 2,
        orderId: 1001,
        productId: products[2].id,
        quantity: 1,
        unitPrice: products[2].price,
        totalPrice: products[2].price,
        notes: products[2].name,
      ),
    ];

    final subtotal =
        orderItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final tax = double.parse((subtotal * 0.15).toStringAsFixed(2));
    final deliveryFee = 9.0;

    _orders = {
      1001: Order(
        id: 1001,
        tenantId: 1,
        branchId: 1,
        customerId: 501,
        orderType: OrderType.delivery,
        status: OrderStatus.preparing,
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        deliveryFee: deliveryFee,
        total: subtotal + tax + deliveryFee,
        paymentMethod: PaymentMethod.card,
        paymentStatus: PaymentStatus.processing,
        driverId: 301,
        deliveryAddress: 'Al Olaya, Riyadh',
        scheduledTime: null,
        notes: 'Extra pickles on the side',
        createdAt: _now.subtract(const Duration(minutes: 18)),
        updatedAt: _now,
      ),
    };

    _orderTimelines = {
      1001: [
        OrderTrackingUpdate(
          orderId: 1001,
          stage: OrderTrackingStage.placed,
          timestamp: _now.subtract(const Duration(minutes: 22)),
          message: 'Order placed via mobile app',
          progress: 0.1,
          etaMinutes: 40,
        ),
        OrderTrackingUpdate(
          orderId: 1001,
          stage: OrderTrackingStage.confirmed,
          timestamp: _now.subtract(const Duration(minutes: 21)),
          message: 'Restaurant confirmed your order',
          progress: 0.25,
          etaMinutes: 35,
        ),
        OrderTrackingUpdate(
          orderId: 1001,
          stage: OrderTrackingStage.preparing,
          timestamp: _now.subtract(const Duration(minutes: 15)),
          message: 'Chef started preparing your dishes',
          progress: 0.55,
          etaMinutes: 25,
        ),
        OrderTrackingUpdate(
          orderId: 1001,
          stage: OrderTrackingStage.driverAssigned,
          timestamp: _now.subtract(const Duration(minutes: 8)),
          message: 'Driver Ahmed picked up the order',
          progress: 0.75,
          etaMinutes: 15,
        ),
        OrderTrackingUpdate(
          orderId: 1001,
          stage: OrderTrackingStage.onTheWay,
          timestamp: _now.subtract(const Duration(minutes: 5)),
          message: 'Driver is on the way to you',
          progress: 0.9,
          etaMinutes: 9,
          driverLatitude: 24.7136,
          driverLongitude: 46.6753,
        ),
      ],
    };

    _driverRoutes = {
      1001: List.generate(6, (index) {
        final offset = index * 0.0015;
        return DriverRoutePoint(
          id: '1001_$index',
          taskId: 'order_1001',
          latitude: 24.706 + offset,
          longitude: 46.672 + offset,
          recordedAt: _now.subtract(Duration(minutes: 10 - index * 2)),
          speedKph: 32 + _random.nextDouble() * 8,
          accuracy: 4.5,
          heading: 95,
          intervalSeconds: 60,
        );
      }),
    };

    _loyaltySummary = LoyaltySummary(
      customerId: 501,
      pointsBalance: 1240,
      tier: 'Gold',
      nextTierThreshold: 1500,
      rewards: [
        LoyaltyReward(
          id: 'reward_free_delivery',
          title: 'Free Delivery Voucher',
          description: 'Waive delivery fees on your next order',
          pointsRequired: 0,
          expiresAt: _now.add(const Duration(days: 10)),
          code: 'DELIVERFREE',
        ),
        LoyaltyReward(
          id: 'reward_20_off',
          title: '20% off Signature Dishes',
          description: 'Save on selected mains above SAR 80',
          pointsRequired: 900,
          expiresAt: _now.add(const Duration(days: 30)),
        ),
        LoyaltyReward(
          id: 'reward_dessert',
          title: 'Complimentary Dessert',
          description: 'Treat yourself to any dessert on the menu',
          pointsRequired: 600,
          redeemedAt: _now.subtract(const Duration(days: 2)),
        ),
      ],
      ordersThisMonth: 6,
      freeDeliveryVouchers: 1,
      lastUpdated: _now,
    );
  }

  List<MenuSection> _buildSections(List<Product> products) {
    return _categories.map((category) {
      final items = products
          .where((product) => product.categoryId == category.id)
          .toList();
      return MenuSection(
        id: 'category_${category.id}',
        name: category.name,
        description: category.description,
        category: category,
        items: items,
      );
    }).toList();
  }

  Future<List<RestaurantSummary>> getFeaturedRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _restaurants.take(3).toList();
  }

  Future<List<RestaurantSummary>> getNearbyRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _restaurants
        .where((restaurant) => restaurant.distanceKm <= 3.5)
        .toList();
  }

  Future<List<RestaurantSummary>> getPopularRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final sorted = [..._restaurants]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(4).toList();
  }

  Future<List<Product>> getRecommendedItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final allItems = _restaurantDetails.values
        .expand((detail) => detail.sections)
        .expand((section) => section.items)
        .toList();
    final featured =
        allItems.where((product) => product.isFeatured ?? false).toList();
    if (featured.length < 6) {
      final remaining =
          allItems.where((product) => !(product.isFeatured ?? false)).toList();
      remaining.shuffle(_random);
      featured.addAll(remaining.take(6 - featured.length));
    }
    return featured.take(6).toList();
  }

  Future<RestaurantDetail> getRestaurantDetail(int restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final detail = _restaurantDetails[restaurantId];
    if (detail == null) {
      throw StateError('Restaurant $restaurantId not found');
    }
    return detail;
  }

  Future<List<Product>> searchMenu(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.isEmpty) {
      return const [];
    }
    final lower = query.toLowerCase();
    return _restaurantDetails.values
        .expand((detail) => detail.sections)
        .expand((section) => section.items)
        .where((product) =>
            product.name.toLowerCase().contains(lower) ||
            product.description.toLowerCase().contains(lower))
        .toList();
  }

  Future<LoyaltySummary> getLoyaltySummary({required int customerId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (customerId != _loyaltySummary.customerId) {
      return _loyaltySummary.copyWith(customerId: customerId);
    }
    return _loyaltySummary;
  }

  Future<Order> getOrder(int orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final order = _orders[orderId];
    if (order == null) {
      throw StateError('Order $orderId not found');
    }
    return order;
  }

  Stream<OrderTrackingUpdate> watchOrderProgress(int orderId) async* {
    final timeline = _orderTimelines[orderId];
    if (timeline == null || timeline.isEmpty) {
      yield OrderTrackingUpdate(
        orderId: orderId,
        stage: OrderTrackingStage.placed,
        timestamp: DateTime.now(),
        message: 'Order placed',
        progress: 0.1,
      );
      return;
    }
    for (final update in timeline) {
      yield update;
      await Future.delayed(const Duration(seconds: 6));
    }
  }

  Stream<DriverRoutePoint> watchDriverRoute(int orderId) async* {
    final route = _driverRoutes[orderId];
    if (route == null) {
      return;
    }
    for (final point in route) {
      yield point;
      await Future.delayed(const Duration(seconds: 8));
    }
  }

  Future<Map<String, dynamic>> getDriverSummary(int orderId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'id': 'driver_301',
      'name': 'Ahmed Hassan',
      'phone': '+966 58 234 9876',
      'vehicle': 'Toyota Raize - Blue',
      'rating': 4.9,
    };
  }

  Future<List<CartItem>> buildCartSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final detail = _restaurantDetails[1]!;
    return detail.sections
        .expand((section) => section.items)
        .take(3)
        .map((product) => CartItem(
              id: product.id,
              product: product,
              quantity: 1,
              unitPrice: product.price,
              totalPrice: product.price,
            ))
        .toList();
  }
}
