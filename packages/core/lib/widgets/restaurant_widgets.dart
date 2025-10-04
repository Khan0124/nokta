import 'package:flutter/material.dart';
import 'package:nokta_core/l10n/app_localizations.dart';
import 'package:nokta_core/models/product.dart';
import 'package:nokta_core/models/restaurant_summary.dart';

class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({
    super.key,
    required this.detail,
    this.onToggleFavorite,
  });

  final RestaurantDetail detail;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = detail.summary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade200,
              image: summary.heroImage.isNotEmpty
                  ? DecorationImage(
                      image: AssetImage(summary.heroImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: summary.heroImage.isEmpty
                ? Icon(
                    Icons.restaurant,
                    color: Colors.grey.shade500,
                    size: 36,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.cuisine,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _RatingChip(rating: summary.rating, count: summary.ratingCount),
                    _InfoChip(
                      icon: Icons.schedule,
                      label: l10n.translate(
                        'customer.restaurant.eta',
                        params: {
                          'time':
                              '${summary.estimatedDeliveryMinutes.min}-${summary.estimatedDeliveryMinutes.max}',
                        },
                      ),
                    ),
                    _InfoChip(
                      icon: Icons.delivery_dining,
                      label: summary.deliveryFee == 0
                          ? l10n.translate('customer.restaurant.freeDelivery')
                          : l10n.formatCurrency(summary.deliveryFee),
                    ),
                  ],
                ),
                if (summary.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFavorite,
            icon: Icon(
              detail.summary.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: detail.summary.isFavorite
                  ? Theme.of(context).colorScheme.error
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class RestaurantInfo extends StatelessWidget {
  const RestaurantInfo({super.key, required this.detail});

  final RestaurantDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('customer.restaurant.aboutTitle'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.about,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: l10n.translate('customer.restaurant.address'),
            value: detail.address,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: l10n.translate('customer.restaurant.phone'),
            value: detail.phone,
          ),
          _InfoRow(
            icon: Icons.watch_later_outlined,
            label: l10n.translate('customer.restaurant.hours'),
            value: detail.openingHours,
          ),
          _InfoRow(
            icon: Icons.payments_outlined,
            label: l10n.translate('customer.restaurant.paymentMethods'),
            value: detail.paymentMethods.join(', '),
          ),
          if (detail.chefNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.translate('customer.restaurant.chefNotes'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ...detail.chefNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(note)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CategoryTabBarDelegate extends SliverPersistentHeaderDelegate {
  CategoryTabBarDelegate({
    required this.sections,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final List<MenuSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 4 : 0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemBuilder: (context, index) {
          final section = sections[index];
          final isSelected = index == selectedIndex;
          return ChoiceChip(
            label: Text(section.name),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(index),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: sections.length,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CategoryTabBarDelegate oldDelegate) {
    return oldDelegate.sections != sections ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.section,
    required this.onProductSelected,
  });

  final MenuSection section;
  final void Function(Product product) onProductSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (section.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    section.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
        ),
        ...section.items.map(
          (product) => _ProductCard(
            product: product,
            addLabel: l10n.translate('customer.restaurant.addToCart'),
            onTap: () => onProductSelected(product),
          ),
        ),
      ],
    );
  }
}

class CartBottomBar extends StatelessWidget {
  const CartBottomBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.buttonLabel,
    required this.onCheckout,
  });

  final int itemCount;
  final double total;
  final String buttonLabel;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.translate('customer.cart.items',
                        params: {'count': '$itemCount'}),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  Text(
                    l10n.formatCurrency(total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: itemCount > 0 ? onCheckout : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text('$rating'),
          const SizedBox(width: 4),
          Text('($count)', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.addLabel,
    required this.onTap,
  });

  final Product product;
  final String addLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.fastfood,
                  color: Colors.grey.shade500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (product.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          product.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          context.l10n.formatCurrency(product.price),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(addLabel),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
