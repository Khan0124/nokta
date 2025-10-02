import 'package:flutter/material.dart';
import 'package:nokta_core/models/customer_address.dart';

class AddressSelector extends StatelessWidget {
  final List<CustomerAddress> addresses;
  final CustomerAddress? selectedAddress;
  final ValueChanged<CustomerAddress> onSelected;
  final VoidCallback onAddNew;

  const AddressSelector({
    super.key,
    required this.addresses,
    required this.selectedAddress,
    required this.onSelected,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (addresses.isEmpty)
          const Text('No addresses found. Please add a new address.')
        else
          ...addresses.map((address) {
            final isSelected = selectedAddress?.id == address.id;
            return RadioListTile<CustomerAddress>(
              value: address,
              groupValue: selectedAddress,
              onChanged: (value) => onSelected(value!),
              title: Text(
                address.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(address.address),
              secondary: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            );
          }).toList(),
      ],
    );
  }
}
