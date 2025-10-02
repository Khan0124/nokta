import 'package:flutter/material.dart';
import 'package:nokta_core/models/dashboard_stats.dart';

class TopRestaurantsTable extends StatelessWidget {
  final List<RestaurantData> restaurants;

  const TopRestaurantsTable({
    super.key,
    required this.restaurants,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const Center(
        child: Text('No restaurant data available'),
      );
    }

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('Restaurant', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Revenue', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Orders', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // Table rows
        ...restaurants.map((restaurant) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    restaurant.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    '\$${restaurant.revenue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    restaurant.orders.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
