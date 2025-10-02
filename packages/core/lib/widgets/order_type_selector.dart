import 'package:flutter/material.dart';
import 'package:nokta_core/models/order.dart';

class OrderTypeSelector extends StatelessWidget {
  final OrderType selectedType;
  final List<OrderType> availableTypes;
  final ValueChanged<OrderType> onChanged;

  const OrderTypeSelector({
    super.key,
    required this.selectedType,
    required this.availableTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: availableTypes.map((type) {
            final isSelected = type == selectedType;
            return ChoiceChip(
              label: Text(type.name.replaceAll('_', ' ').toUpperCase()),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
              selectedColor: Theme.of(context).primaryColor.withAlpha(100),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
