// apps/customer_app/lib/screens/restaurant/restaurant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

class RestaurantScreen extends ConsumerWidget {
  final int restaurantId;

  const RestaurantScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(restaurantProvider);
    final cart = ref.watch(cartProvider);

    return restaurantAsync.when(
      data: (restaurant) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: RestaurantHeader(restaurant: restaurant),
            ),
            SliverToBoxAdapter(
              child: RestaurantInfo(restaurant: restaurant),
            ),
            SliverPersistentHeader(
              delegate: CategoryTabBarDelegate(
                categories: restaurant['categories'] ?? [],
                onCategorySelected: (index) {
                  // TODO: Handle category selection
                },
                selectedIndex: 0,
              ),
              pinned: true,
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = restaurant['categories'][index];
                  final categoryProducts = (restaurant['products'] as List)
                      .where((product) => product['category'] == category)
                      .map((product) => product as Map<String, dynamic>)
                      .toList();

                  return CategorySection(
                    category: category,
                    products: categoryProducts,
                    onProductTap: (product) {
                      // TODO: Add to cart
                      print('Adding to cart: ${product['name']}');
                    },
                  );
                },
                childCount: (restaurant['categories'] as List).length,
              ),
            ),
          ],
        ),
        bottomNavigationBar: cart.items.isNotEmpty
            ? CartBottomBar(
                itemCount: cart.items.length,
                total: cart.total,
                onCheckout: () {
                  // TODO: Navigate to checkout
                  print('Navigate to checkout');
                },
              )
            : null,
      ),
      loading: () => const LoadingScreen(),
      error: (error, stack) => ErrorScreen(
        message: 'Error loading restaurant: $error',
        onRetry: () => ref.refresh(restaurantProvider),
      ),
    );
  }
}
