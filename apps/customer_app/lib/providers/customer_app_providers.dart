import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

final currentCustomerIdProvider = Provider<int>((ref) => 501);

final loyaltySummaryProvider = FutureProvider<LoyaltySummary>((ref) {
  final service = ref.watch(customerExperienceServiceProvider);
  final customerId = ref.watch(currentCustomerIdProvider);
  return service.getLoyaltySummary(customerId: customerId);
});

final featuredRestaurantsProvider = FutureProvider<List<RestaurantSummary>>((ref) {
  return ref.watch(customerExperienceServiceProvider).getFeaturedRestaurants();
});

final nearbyRestaurantsProvider = FutureProvider<List<RestaurantSummary>>((ref) {
  return ref.watch(customerExperienceServiceProvider).getNearbyRestaurants();
});

final popularRestaurantsProvider = FutureProvider<List<RestaurantSummary>>((ref) {
  return ref.watch(customerExperienceServiceProvider).getPopularRestaurants();
});

final recommendedItemsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(customerExperienceServiceProvider).getRecommendedItems();
});

final restaurantDetailProvider =
    FutureProvider.family<RestaurantDetail, int>((ref, restaurantId) {
  return ref
      .watch(customerExperienceServiceProvider)
      .getRestaurantDetail(restaurantId);
});

final menuSearchProvider = FutureProvider.family<List<Product>, String>((ref, q) {
  return ref.watch(customerExperienceServiceProvider).searchMenu(q);
});

final orderDetailProvider = FutureProvider.family<Order, int>((ref, orderId) {
  return ref.watch(customerExperienceServiceProvider).getOrder(orderId);
});

final orderTimelineProvider =
    StreamProvider.family<OrderTrackingUpdate, int>((ref, orderId) {
  return ref.watch(customerExperienceServiceProvider).watchOrderProgress(orderId);
});

final driverRouteProvider =
    StreamProvider.family<DriverRoutePoint?, int>((ref, orderId) {
  return ref
      .watch(customerExperienceServiceProvider)
      .watchDriverRoute(orderId)
      .map((point) => point);
});

final driverSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, orderId) {
  return ref.watch(customerExperienceServiceProvider).getDriverSummary(orderId);
});

final cartSuggestionsProvider = FutureProvider<List<CartItem>>((ref) {
  return ref.watch(customerExperienceServiceProvider).buildCartSuggestions();
});
