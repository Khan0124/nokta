import 'package:flutter/material.dart';

class OrderTypePieChart extends StatelessWidget {
  final Map<String, int> data;

  const OrderTypePieChart({
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

    final total = data.values.reduce((a, b) => a + b);
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

    return Column(
      children: [
        // Simple pie chart representation
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: PieChartPainter(data, total, colors),
            size: const Size(200, 200),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        ...data.entries.map((entry) {
          final index = data.keys.toList().indexOf(entry.key);
          final color = colors[index % colors.length];
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value} ($percentage%)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, int> data;
  final int total;
  final List<Color> colors;

  PieChartPainter(this.data, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    double startAngle = 0;
    int index = 0;
    
    for (final entry in data.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      final color = colors[index % colors.length];
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
