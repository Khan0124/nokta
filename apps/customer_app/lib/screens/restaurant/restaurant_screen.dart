import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nokta_core/nokta_core.dart';

import '../../providers/customer_app_providers.dart';

class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key, required this.restaurantId});

  final int restaurantId;

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailAsync = ref.watch(restaurantDetailProvider(widget.restaurantId));
    final cart = ref.watch(cartProvider);

    return detailAsync.when(
      data: (detail) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              flexibleSpace: FlexibleSpaceBar(
                background: RestaurantHeader(detail: detail),
              ),
            ),
            SliverToBoxAdapter(
              child: RestaurantInfo(detail: detail),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: CategoryTabBarDelegate(
                sections: detail.sections,
                selectedIndex: _selectedCategory,
                onCategorySelected: (index) {
                  setState(() => _selectedCategory = index);
                },
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => CategorySection(
                  section: detail.sections[index],
                  onProductSelected: (product) => _showAddToCartSheet(product),
                ),
                childCount: detail.sections.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 120),
            ),
          ],
        ),
        bottomNavigationBar: CartBottomBar(
          itemCount: cart.itemCount,
          total: cart.total,
          buttonLabel: l10n.translate('customer.restaurant.viewCart'),
          onCheckout: () => context.push('/checkout'),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.translate('customer.common.error'))),
        body: Center(
          child: Text(
            '$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddToCartSheet(Product product) async {
    final l10n = context.l10n;
    final cartNotifier = ref.read(cartProvider.notifier);
    int quantity = 1;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final total = product.price * quantity;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.translate('customer.restaurant.quantity')),
                      Row(
                        children: [
                          IconButton(
                            onPressed: quantity > 1
                                ? () => setState(() => quantity -= 1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$quantity',
                              style: Theme.of(context).textTheme.titleMedium),
                          IconButton(
                            onPressed: () => setState(() => quantity += 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      cartNotifier.addItem(product, quantity: quantity);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.translate('customer.restaurant.addedToCart',
                              params: {'product': product.name})),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: Text(l10n.translate('customer.restaurant.addItemButton',
                        params: {'price': l10n.formatCurrency(total)})),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
