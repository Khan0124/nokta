import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nokta_core/nokta_core.dart';

import '../../providers/customer_app_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  OrderType _orderType = OrderType.delivery;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  CustomerAddress? _selectedAddress;
  DateTime? _scheduledTime;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(customerAddressesProvider);
    final suggestions = ref.watch(cartSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('customer.checkout.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('customer.checkout.fulfilment'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            OrderTypeSelector(
              selectedType: _orderType,
              availableTypes: const [
                OrderType.delivery,
                OrderType.takeaway,
              ],
              onChanged: (type) => setState(() => _orderType = type),
            ),
            if (_orderType == OrderType.delivery) ...[
              const SizedBox(height: 20),
              _AsyncSection<List<CustomerAddress>>(
                value: addresses,
                builder: (items) => AddressSelector(
                  addresses: items,
                  selectedAddress: _selectedAddress,
                  onSelected: (address) => setState(() => _selectedAddress = address),
                  onAddNew: () => _showAddAddressDialog(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(l10n.translate('customer.checkout.schedule'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ScheduleTimeSelector(
              selectedTime: _scheduledTime,
              onChanged: (time) => setState(() => _scheduledTime = time),
            ),
            const SizedBox(height: 20),
            Text(l10n.translate('customer.checkout.summary'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            OrderSummaryCard(cart: cart),
            const SizedBox(height: 20),
            Text(l10n.translate('customer.checkout.payment'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            PaymentMethodSelector(
              selectedMethod: _paymentMethod,
              availableMethods: const [
                PaymentMethod.cash,
                PaymentMethod.card,
                PaymentMethod.mobilePayment,
              ],
              onChanged: (method) => setState(() => _paymentMethod = method),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.translate('customer.checkout.notesLabel'),
                hintText: l10n.translate('customer.checkout.notesHint'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(l10n.translate('customer.checkout.suggestions'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _AsyncSection<List<CartItem>>(
              value: suggestions,
              builder: (items) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => ActionChip(
                        label: Text(item.product.name),
                        avatar: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .addItem(item.product),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _canPlaceOrder(cart)
                ? () => _placeOrder(cart)
                : null,
            icon: const Icon(Icons.lock_clock),
            label: Text(l10n.translate('customer.checkout.placeOrderButton',
                params: {'total': l10n.formatCurrency(cart.total)})),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
      ),
    );
  }

  bool _canPlaceOrder(CartState cart) {
    if (cart.items.isEmpty) return false;
    if (_orderType == OrderType.delivery && _selectedAddress == null) {
      return false;
    }
    return true;
  }

  Future<void> _placeOrder(CartState cart) async {
    final l10n = context.l10n;
    final cartNotifier = ref.read(cartProvider.notifier);
    try {
      final order = await cartNotifier.checkout(
        tenantId: 1,
        branchId: 1,
        customerId: ref.read(currentCustomerIdProvider),
        orderType: _orderType,
        deliveryAddress: _selectedAddress?.address,
        scheduledTime: _scheduledTime,
        notes: _notesController.text,
      );

      cartNotifier.updateOrderAfterPayment(order, _paymentMethod);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('customer.checkout.success')),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/order/${order.id == 0 ? 1001 : order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('customer.checkout.error', params: {'error': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddAddressDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('customer.checkout.addAddressTitle')),
        content: Text(l10n.translate('customer.checkout.addAddressBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('customer.common.close')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

class _AsyncSection<T> extends StatelessWidget {
  const _AsyncSection({required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text(
        context.l10n.translate('customer.common.errorLoading'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
