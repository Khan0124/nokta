import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nokta_core/nokta_core.dart';

import '../../providers/customer_app_providers.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loyalty = ref.watch(loyaltySummaryProvider);
    final featured = ref.watch(featuredRestaurantsProvider);
    final popular = ref.watch(popularRestaurantsProvider);
    final nearby = ref.watch(nearbyRestaurantsProvider);
    final recommended = ref.watch(recommendedItemsProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loyaltySummaryProvider);
          ref.invalidate(featuredRestaurantsProvider);
          ref.invalidate(popularRestaurantsProvider);
          ref.invalidate(nearbyRestaurantsProvider);
          ref.invalidate(recommendedItemsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              expandedHeight: 220,
              flexibleSpace: FlexibleSpaceBar(
                background: _HomeHeader(onSearchTap: () => context.push('/search')),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AsyncValueBuilder<LoyaltySummary>(
                      value: loyalty,
                      builder: (summary) => _LoyaltyOverviewCard(summary: summary),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: l10n.translate('customer.home.featuredTitle'),
                      onViewAll: () => context.push('/search'),
                    ),
                    _AsyncValueBuilder<List<RestaurantSummary>>(
                      value: featured,
                      builder: (restaurants) => _FeaturedRestaurants(restaurants: restaurants),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: l10n.translate('customer.home.popularTitle'),
                      onViewAll: () => context.push('/search'),
                    ),
                    _AsyncValueBuilder<List<RestaurantSummary>>(
                      value: popular,
                      builder: (restaurants) => _HorizontalRestaurantList(restaurants: restaurants),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: l10n.translate('customer.home.nearbyTitle'),
                      onViewAll: () => context.push('/search'),
                    ),
                    _AsyncValueBuilder<List<RestaurantSummary>>(
                      value: nearby,
                      builder: (restaurants) => _VerticalRestaurantList(restaurants: restaurants),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: l10n.translate('customer.home.recommendedTitle'),
                    ),
                    _AsyncValueBuilder<List<Product>>(
                      value: recommended,
                      builder: (items) => _RecommendedItems(items: items),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(l10n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/checkout'),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(l10n.translate('customer.home.checkoutButton',
                  params: {'total': l10n.formatCurrency(cart.total)})),
            )
          : null,
    );
  }

  Widget _buildBottomNavigationBar(AppLocalizations l10n) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() => _currentIndex = index);
        switch (index) {
          case 0:
            break;
          case 1:
            context.push('/search');
            break;
          case 2:
            context.push('/order/1001');
            break;
          case 3:
            context.push('/profile');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.translate('customer.nav.home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.search_outlined),
          selectedIcon: const Icon(Icons.search),
          label: l10n.translate('customer.nav.search'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: l10n.translate('customer.nav.orders'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: l10n.translate('customer.nav.profile'),
        ),
      ],
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final localeController = ref.read(localeProvider.notifier);
    final locale = ref.watch(localeProvider);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('customer.home.greeting'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.translate('customer.home.subtitle'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final target = locale.languageCode == 'ar'
                          ? const Locale('en')
                          : const Locale('ar');
                      localeController.setLocale(target);
                    },
                    icon: const Icon(Icons.language),
                    label: Text(
                      locale.languageCode == 'ar'
                          ? 'English'
                          : 'العربية',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Text(
                        l10n.translate('customer.home.searchPlaceholder'),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoyaltyOverviewCard extends StatelessWidget {
  const _LoyaltyOverviewCard({required this.summary});

  final LoyaltySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('customer.loyalty.title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('customer.loyalty.points'),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      Text(
                        summary.pointsBalance.toString(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('customer.loyalty.tier'),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                      Text(
                        summary.tier,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: summary.progressToNextTier,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('customer.loyalty.progress',
                  params: {'points': summary.pointsToNextTier.toString()}),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            if (summary.hasActiveRewards && summary.nextReward != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.nextReward!.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            summary.nextReward!.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
  });

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(context.l10n.translate('customer.common.viewAll')),
          ),
      ],
    );
  }
}

class _FeaturedRestaurants extends StatelessWidget {
  const _FeaturedRestaurants({required this.restaurants});

  final List<RestaurantSummary> restaurants;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: restaurants.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return _RestaurantCard(restaurant: restaurant, compact: true);
        },
      ),
    );
  }
}

class _HorizontalRestaurantList extends StatelessWidget {
  const _HorizontalRestaurantList({required this.restaurants});

  final List<RestaurantSummary> restaurants;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return _RestaurantCard(restaurant: restaurant);
        },
      ),
    );
  }
}

class _VerticalRestaurantList extends StatelessWidget {
  const _VerticalRestaurantList({required this.restaurants});

  final List<RestaurantSummary> restaurants;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: restaurants
          .map((restaurant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RestaurantTile(restaurant: restaurant),
              ))
          .toList(),
    );
  }
}

class _RecommendedItems extends StatelessWidget {
  const _RecommendedItems({required this.items});

  final List<Product> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            width: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    Text(
                      context.l10n.formatCurrency(item.price),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, this.compact = false});

  final RestaurantSummary restaurant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      width: compact ? 220 : 260,
      child: GestureDetector(
        onTap: () => context.push('/restaurant/${restaurant.id}'),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                    const SizedBox(width: 4),
                    Text('${restaurant.rating}'),
                    const SizedBox(width: 4),
                    Text('(${restaurant.ratingCount})',
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (restaurant.isFavorite)
                      Icon(Icons.favorite,
                          color: Theme.of(context).colorScheme.error),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  restaurant.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.cuisine,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  l10n.translate('customer.restaurant.etaShort', params: {
                    'time':
                        '${restaurant.estimatedDeliveryMinutes.min}-${restaurant.estimatedDeliveryMinutes.max}'
                  }),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({required this.restaurant});

  final RestaurantSummary restaurant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      onTap: () => context.push('/restaurant/${restaurant.id}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.restaurant),
      ),
      title: Text(restaurant.name),
      subtitle: Text(
        '${restaurant.cuisine} • ${l10n.translate('customer.restaurant.distance', params: {'distance': restaurant.distanceKm.toStringAsFixed(1)})}',
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${restaurant.rating} ★'),
          Text('${restaurant.estimatedDeliveryMinutes.min}-${restaurant.estimatedDeliveryMinutes.max} ${l10n.translate('customer.common.minutes')}'),
        ],
      ),
    );
  }
}

class _AsyncValueBuilder<T> extends StatelessWidget {
  const _AsyncValueBuilder({
    required this.value,
    required this.builder,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      )),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.translate('customer.common.errorLoading'),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            Text('$error',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
