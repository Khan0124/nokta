import 'package:flutter/material.dart';
import 'package:nokta_core/models/order.dart';
import 'package:nokta_core/providers/cart_provider.dart';

class ScheduleTimeSelector extends StatelessWidget {
  final DateTime? selectedTime;
  final ValueChanged<DateTime?> onChanged;

  const ScheduleTimeSelector({
    super.key,
    required this.selectedTime,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    final now = DateTime.now();
                    final scheduledTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      time.hour,
                      time.minute,
                    );
                    onChanged(scheduledTime);
                  }
                },
                icon: const Icon(Icons.schedule),
                label: Text(selectedTime != null
                    ? '${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select Time'),
              ),
            ),
            if (selectedTime != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear),
                tooltip: 'Clear time',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final CartState cart;

  const OrderSummaryCard({
    super.key,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${item.quantity}x ${item.product.name}'),
                  ),
                  Text('\$${(item.quantity * item.product.price).toStringAsFixed(2)}'),
                ],
              ),
            )).toList(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${cart.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
}

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final List<PaymentMethod> availableMethods;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.availableMethods,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...availableMethods.map((method) => RadioListTile<PaymentMethod>(
          value: method,
          groupValue: selectedMethod,
          onChanged: (value) => onChanged(value!),
          title: Text(method.name.replaceAll('_', ' ').toUpperCase()),
          subtitle: Text(_getPaymentMethodDescription(method)),
        )).toList(),
      ],
    );
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Pay with cash upon delivery';
      case PaymentMethod.card:
        return 'Pay with credit/debit card';
      case PaymentMethod.mobilePayment:
        return 'Pay with mobile payment app';
      case PaymentMethod.bankTransfer:
        return 'Pay via bank transfer';
    }
  }
}
