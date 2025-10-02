import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

// apps/customer_app/lib/screens/checkout/checkout_screen.dart
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
    final cart = ref.watch(cartProvider);
    final addresses = ref.watch(customerAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type Selection
            OrderTypeSelector(
              selectedType: _orderType,
              availableTypes: const [
                OrderType.dineIn,
                OrderType.takeaway,
                OrderType.delivery
              ],
              onChanged: (type) => setState(() => _orderType = type),
            ),

            // Delivery Address (if delivery)
            if (_orderType == OrderType.delivery) ...[
              const SizedBox(height: 24),
              AddressSelector(
                addresses: addresses.value ?? [],
                selectedAddress: _selectedAddress,
                onSelected: (address) =>
                    setState(() => _selectedAddress = address),
                onAddNew: () => _showAddAddressDialog(),
              ),
            ],

            // Schedule Time
            const SizedBox(height: 24),
            ScheduleTimeSelector(
              selectedTime: _scheduledTime,
              onChanged: (time) => setState(() => _scheduledTime = time),
            ),

            // Order Summary
            const SizedBox(height: 24),
            OrderSummaryCard(cart: cart),

            // Payment Method
            const SizedBox(height: 24),
            PaymentMethodSelector(
              selectedMethod: _paymentMethod,
              availableMethods: _getAvailablePaymentMethods(),
              onChanged: (method) => setState(() => _paymentMethod = method),
            ),

            // Notes
            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Any special instructions?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _canPlaceOrder() ? _placeOrder : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text('Place Order - ${formatCurrency(cart.total)}'),
          ),
        ),
      ),
    );
  }

  bool _canPlaceOrder() {
    if (_orderType == OrderType.delivery && _selectedAddress == null) {
      return false;
    }
    return true;
  }

  Future<void> _placeOrder() async {
    try {
      // Create order using the cart provider's checkout method
      final order = await ref.read(cartProvider.notifier).checkout(
            tenantId: 1, // Default tenant ID
            branchId: 1, // Default branch ID
            customerId: 1, // Default customer ID
            orderType: _orderType,
            deliveryAddress: _selectedAddress?.address,
            scheduledTime: _scheduledTime,
            notes: _notesController.text,
          );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order ID: ${order.id}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PaymentMethod> _getAvailablePaymentMethods() {
    return [
      PaymentMethod.cash,
      PaymentMethod.card,
      PaymentMethod.mobilePayment,
    ];
  }

  void _showAddAddressDialog() {
    // TODO: Implement add address dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add address functionality coming soon!'),
      ),
    );
  }
}
