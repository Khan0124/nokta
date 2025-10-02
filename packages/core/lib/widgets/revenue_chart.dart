import 'package:flutter/material.dart';
import 'package:nokta_core/models/dashboard_stats.dart';

class RevenueChart extends StatelessWidget {
  final List<RevenueData> data;

  const RevenueChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Simple bar chart implementation
    final maxAmount = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        // Chart bars
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final height = (item.amount / maxAmount) * 200;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 30,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(150),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${(item.amount / 1000).toStringAsFixed(1)}k',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // X-axis labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((item) {
            return Text(
              '${item.date.month}/${item.date.day}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
