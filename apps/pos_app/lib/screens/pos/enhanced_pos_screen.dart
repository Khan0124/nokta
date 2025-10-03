import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/models/cart_item.dart';
import 'package:nokta_core/models/order.dart';
import 'package:nokta_core/models/product.dart';
import 'package:nokta_core/models/products_query.dart';
import 'package:nokta_core/nokta_core.dart';
import 'package:nokta_core/providers/cart_provider.dart';
import 'package:nokta_core/providers/category_provider.dart';
import 'package:nokta_core/providers/connectivity_provider.dart';
import 'package:nokta_core/providers/feature_flag_provider.dart';
import 'package:nokta_core/providers/dynamic_pricing_provider.dart';
import 'package:nokta_core/providers/offline_queue_provider.dart';
import 'package:nokta_core/providers/pos_order_provider.dart';
import 'package:nokta_core/providers/print_provider.dart';
import 'package:nokta_core/providers/product_provider.dart';
import 'package:nokta_core/providers/sync_provider.dart';
import 'package:nokta_core/services/pos_order_service.dart';
import 'package:nokta_core/services/print_service.dart';
import 'package:nokta_core/services/sync_service.dart';

class EnhancedPOSScreen extends ConsumerStatefulWidget {
  const EnhancedPOSScreen({super.key});

  @override
  ConsumerState<EnhancedPOSScreen> createState() => _EnhancedPOSScreenState();
}

class _EnhancedPOSScreenState extends ConsumerState<EnhancedPOSScreen> {
  int _selectedCategoryId = 0;
  OrderType _orderType = OrderType.dineIn;
  ReceiptLayout _receiptLayout = ReceiptLayout.full;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final locale = ref.watch(localeProvider);
    final l10n = context.l10n;
    final offlineQueueEnabled = ref.watch(featureFlagEnabledProvider('pos.offlineQueue'));
    final enhancedReceiptsEnabled =
        ref.watch(featureFlagEnabledProvider('pos.enhancedReceipts'));

    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final pendingOffline = ref.watch(pendingOfflineOrdersProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    final isOffline = connectivityStatus.maybeWhen(
      data: (status) => status == ConnectivityResult.none,
      orElse: () => false,
    );

    final pendingCount = pendingOffline.maybeWhen(
      data: (count) => count,
      orElse: () => 0,
    );

    final syncState = syncStatus.maybeWhen(
      data: (status) => status,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('pos.screenTitle')),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.refresh(productsProvider(const ProductsQuery())),
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            tooltip: l10n.translate('pos.language'),
            onSelected: (selectedLocale) {
              ref
                  .read(localeProvider.notifier)
                  .setLocale(selectedLocale);
            },
            itemBuilder: (context) => [
              PopupMenuItem<Locale>(
                value: const Locale('ar'),
                child: Text(l10n.translate('pos.languageArabic')),
                enabled: locale.languageCode != 'ar',
              ),
              PopupMenuItem<Locale>(
                value: const Locale('en'),
                child: Text(l10n.translate('pos.languageEnglish')),
                enabled: locale.languageCode != 'en',
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (offlineQueueEnabled && isOffline)
            _buildOfflineBanner(l10n, pendingCount)
          else if (offlineQueueEnabled &&
              ((syncState?.state == SyncState.syncing && pendingCount > 0) ||
                  (pendingCount > 0 && syncState?.state != SyncState.error)))
            _buildSyncBanner(l10n, syncState, pendingCount)
          else if (offlineQueueEnabled && syncState?.state == SyncState.error)
            _buildErrorBanner(l10n, syncState!, pendingCount),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildCategoryTabs(),
                      Expanded(
                        child: _buildProductGrid(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildOrderTypeSelector(),
                        Expanded(
                          child: _buildCartItems(cart.items),
                        ),
                        _buildCartSummary(cart),
                        _buildActionButtons(
                          cart.items,
                          pendingCount,
                          isOffline,
                          offlineQueueEnabled,
                          enhancedReceiptsEnabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: categoriesAsync.when(
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(l10n.translate('pos.allFilter')),
                  selected: _selectedCategoryId == 0,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategoryId = 0);
                  },
                ),
              );
            }

            final category = categories[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category.name),
                selected: _selectedCategoryId == category.id,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategoryId = category.id);
                  }
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('${l10n.translate('pos.errorLoading')}: $error'),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final l10n = context.l10n;
    final query = ProductsQuery(
      categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId,
      isAvailable: true,
    );
    final productsAsync = ref.watch(productsProvider(query));

    return productsAsync.when(
      data: (products) {
        final adjustmentsAsync = ref.watch(dynamicPricingAdjustmentsProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            adjustmentsAsync.maybeWhen(
              data: (adjustments) {
                if (adjustments.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildDynamicPricingHighlights(adjustments);
              },
              loading: () => const LinearProgressIndicator(minHeight: 2),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(product);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${l10n.translate('pos.errorLoading')}: $error'),
      ),
    );
  }

  Widget _buildDynamicPricingHighlights(List<DynamicPriceAdjustment> adjustments) {
    final activeAdjustments = adjustments
        .where((adjustment) => adjustment.status == DynamicPriceStatus.active)
        .toList();
    if (activeAdjustments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.translate('pos.activeOffers'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: activeAdjustments.map((adjustment) {
              return Chip(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                label: Text(
                  adjustment.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final l10n = context.l10n;
    final dynamicPrice = ref.watch(productDynamicPriceProvider(product));
    final hasAdjustment = (product.price - dynamicPrice).abs() > 0.009;
    final discountPercentage = hasAdjustment && product.price > 0
        ? ((product.price - dynamicPrice) / product.price * 100).clamp(-100, 100)
        : 0.0;
    return Card(
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        child: Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.restaurant, size: 40),
                        ),
                      )
                    : const Icon(Icons.restaurant, size: 40),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      l10n.formatCurrency(
                        dynamicPrice,
                        currencyCode: 'SAR',
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasAdjustment
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    if (hasAdjustment)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              l10n.formatCurrency(
                                product.price,
                                currencyCode: 'SAR',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.outline,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.trending_down,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${discountPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.translate('pos.orderType'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<OrderType>(
            segments: [
              ButtonSegment(
                value: OrderType.dineIn,
                label: Text(l10n.translate('pos.orderTypeDineIn')),
                icon: const Icon(Icons.restaurant),
              ),
              ButtonSegment(
                value: OrderType.takeaway,
                label: Text(l10n.translate('pos.orderTypeTakeaway')),
                icon: const Icon(Icons.shopping_bag),
              ),
              ButtonSegment(
                value: OrderType.delivery,
                label: Text(l10n.translate('pos.orderTypeDelivery')),
                icon: const Icon(Icons.delivery_dining),
              ),
            ],
            selected: {_orderType},
            onSelectionChanged: (types) {
              setState(() => _orderType = types.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(List<CartItem> cartItems) {
    final l10n = context.l10n;
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.translate('pos.cartEmptyTitle'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              l10n.translate('pos.cartEmptySubtitle'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return _buildCartItem(item);
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromCart(item.product),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    ref.read(cartProvider.notifier).updateItemQuantity(
                          item.id,
                          item.quantity - 1,
                        );
                  },
                ),
                Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    ref.read(cartProvider.notifier).updateItemQuantity(
                          item.id,
                          item.quantity + 1,
                        );
                  },
                ),
                const Spacer(),
                Text(
                  l10n.formatCurrency(
                    item.totalPrice,
                    currencyCode: 'SAR',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartState cart) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.translate('pos.subtotal')),
              Text(
                l10n.formatCurrency(
                  cart.subtotal,
                  currencyCode: 'SAR',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.translate('pos.tax')),
              Text(
                l10n.formatCurrency(
                  cart.tax,
                  currencyCode: 'SAR',
                ),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('pos.total'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                l10n.formatCurrency(
                  cart.total,
                  currencyCode: 'SAR',
                ),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    List<CartItem> cartItems,
    int pendingCount,
    bool isOffline,
    bool offlineQueueEnabled,
    bool enhancedReceiptsEnabled,
  ) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _clearCart(),
                  icon: const Icon(Icons.clear),
                  label: Text(l10n.translate('pos.clearCart')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cartItems.isEmpty ? null : () => _holdOrder(),
                  icon: const Icon(Icons.pause),
                  label: Text(l10n.translate('pos.holdOrder')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (offlineQueueEnabled && pendingCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.translate(
                    'pos.pendingOrdersLabel',
                    params: {'count': '$pendingCount'},
                  ),
                  style: TextStyle(
                    color: isOffline ? Colors.orange.shade700 : Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ),
          if (enhancedReceiptsEnabled)
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<ReceiptLayout>(
                segments: [
                  ButtonSegment(
                    value: ReceiptLayout.compact,
                    label: Text(l10n.translate('pos.receiptCompact')),
                    icon: const Icon(Icons.receipt_long),
                  ),
                  ButtonSegment(
                    value: ReceiptLayout.full,
                    label: Text(l10n.translate('pos.receiptFull')),
                    icon: const Icon(Icons.print),
                  ),
                ],
                selected: {_receiptLayout},
                onSelectionChanged: (selection) {
                  setState(() => _receiptLayout = selection.first);
                },
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.print, size: 18),
                label: Text(l10n.translate('pos.receiptFull')),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed:
                  cartItems.isEmpty || _isProcessing ? null : () => _processPayment(),
              icon: const Icon(Icons.payment),
              label: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.translate('pos.checkout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    ref.read(cartProvider.notifier).addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.translate(
            'pos.addedToCart',
            params: {'product': product.name},
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(Product product) {
    ref.read(cartProvider.notifier).removeItem(product.id);
  }

  void _updateQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _removeFromCart(product);
    } else {
      // Find the cart item for this product and update its quantity
      final cartItem = ref.read(cartProvider).items.firstWhere(
            (item) => item.product.id == product.id,
            orElse: () => throw Exception('Product not found in cart'),
          );
      ref.read(cartProvider.notifier).updateItemQuantity(cartItem.id, quantity);
    }
  }

  void _clearCart() {
    ref.read(cartProvider.notifier).clearCart();
  }

  void _holdOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.translate('pos.orderHeld'))),
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final cartState = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final order = await cartNotifier.checkout(
        tenantId: 1,
        branchId: 1,
        customerId: 1,
        orderType: _orderType,
        notes: cartState.notes,
      );

      final submission = await ref
          .read(posOrderServiceProvider)
          .submit(order.copyWith(updatedAt: DateTime.now()));

      if (!mounted) return;

      final successMessage = submission.wasQueued
          ? context.l10n.translate(
              'pos.orderQueued',
              params: {
                'reference':
                    '${submission.queueId ?? submission.order.id}',
              },
            )
          : context.l10n.translate(
              'pos.orderSynced',
              params: {'order': '${submission.order.id}'},
            );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );

      try {
        await ref.read(printServiceProvider).printReceipt(
              submission.order,
              layout: _receiptLayout,
              offlineReference: submission.queueId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.translate('pos.receiptPrinted')),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.translate('pos.printError')),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.translate('common.error')}: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildOfflineBanner(AppLocalizations l10n, int pendingCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('pos.offlineModeTitle'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(l10n.translate('pos.offlineModeSubtitle')),
                if (pendingCount > 0)
                  Text(
                    l10n.translate(
                      'pos.pendingOrdersLabel',
                      params: {'count': '$pendingCount'},
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner(
    AppLocalizations l10n,
    SyncStatus? status,
    int pendingCount,
  ) {
    final syncing = status?.state == SyncState.syncing;
    final lastSynced = status?.lastSyncedAt != null
        ? l10n.formatDateTime(status!.lastSyncedAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: syncing ? Colors.blue.shade50 : Colors.grey.shade200,
      child: Row(
        children: [
          Icon(
            syncing ? Icons.sync : Icons.cloud_done,
            color: syncing ? Colors.blue : Colors.teal,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncing
                      ? l10n.translate(
                          'pos.syncInProgress',
                          params: {'count': '$pendingCount'},
                        )
                      : l10n.translate(
                          'pos.syncPending',
                          params: {'count': '$pendingCount'},
                        ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (lastSynced != null)
                  Text(
                    l10n.translate(
                      'pos.lastSyncedAt',
                      params: {'time': lastSynced},
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    AppLocalizations l10n,
    SyncStatus status,
    int pendingCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.red.shade50,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate(
                    'pos.syncErrorStatus',
                    params: {'count': '$pendingCount'},
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (status.message != null)
                  Text(status.message!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
