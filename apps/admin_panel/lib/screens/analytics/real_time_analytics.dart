import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Real-time stats provider
final realTimeStatsProvider =
    StateNotifierProvider<RealTimeStatsNotifier, RealTimeStats>((ref) {
  return RealTimeStatsNotifier();
});

// Real-time stats model
class RealTimeStats {
  final int activeUsers;
  final int activeOrders;
  final double currentRevenue;
  final int kitchenOrders;
  final int deliveryOrders;
  final List<double> revenueHistory;
  final List<int> ordersHistory;

  RealTimeStats({
    this.activeUsers = 0,
    this.activeOrders = 0,
    this.currentRevenue = 0.0,
    this.kitchenOrders = 0,
    this.deliveryOrders = 0,
    this.revenueHistory = const [],
    this.ordersHistory = const [],
  });

  RealTimeStats copyWith({
    int? activeUsers,
    int? activeOrders,
    double? currentRevenue,
    int? kitchenOrders,
    int? deliveryOrders,
    List<double>? revenueHistory,
    List<int>? ordersHistory,
  }) {
    return RealTimeStats(
      activeUsers: activeUsers ?? this.activeUsers,
      activeOrders: activeOrders ?? this.activeOrders,
      currentRevenue: currentRevenue ?? this.currentRevenue,
      kitchenOrders: kitchenOrders ?? this.kitchenOrders,
      deliveryOrders: deliveryOrders ?? this.deliveryOrders,
      revenueHistory: revenueHistory ?? this.revenueHistory,
      ordersHistory: ordersHistory ?? this.ordersHistory,
    );
  }
}

// Real-time stats notifier
class RealTimeStatsNotifier extends StateNotifier<RealTimeStats> {
  Timer? _timer;
  final _random = math.Random();

  RealTimeStatsNotifier() : super(RealTimeStats()) {
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Simulate real-time data updates
      final newRevenue = state.currentRevenue + (_random.nextDouble() * 100);
      final newOrders = state.activeOrders + (_random.nextBool() ? 1 : 0);

      List<double> revenueHistory = [...state.revenueHistory, newRevenue];
      if (revenueHistory.length > 20) {
        revenueHistory = revenueHistory.sublist(1);
      }

      List<int> ordersHistory = [...state.ordersHistory, newOrders];
      if (ordersHistory.length > 20) {
        ordersHistory = ordersHistory.sublist(1);
      }

      state = state.copyWith(
        activeUsers: 50 + _random.nextInt(20),
        activeOrders: newOrders,
        currentRevenue: newRevenue,
        kitchenOrders: 5 + _random.nextInt(10),
        deliveryOrders: 3 + _random.nextInt(7),
        revenueHistory: revenueHistory,
        ordersHistory: ordersHistory,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Real-time Analytics Screen
class RealTimeAnalyticsScreen extends ConsumerWidget {
  const RealTimeAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(realTimeStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Real-Time Analytics',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh data
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Users',
                    stats.activeUsers.toString(),
                    Icons.people,
                    Colors.blue,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Orders',
                    stats.activeOrders.toString(),
                    Icons.receipt_long,
                    Colors.orange,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Today\'s Revenue',
                    '\$${stats.currentRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Real-time Revenue Chart
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Revenue Stream',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return const FlLine(
                              color: Colors.white24,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: stats.revenueHistory
                                .asMap()
                                .entries
                                .map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value);
                            }).toList(),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withAlpha(51),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Kitchen & Delivery Status
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    context,
                    'Kitchen Orders',
                    stats.kitchenOrders,
                    Icons.restaurant,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    context,
                    'Delivery Orders',
                    stats.deliveryOrders,
                    Icons.delivery_dining,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool showPulse,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (showPulse)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
