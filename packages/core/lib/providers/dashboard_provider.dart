import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  // TODO: Implement actual API call to get dashboard stats
  // For now, return mock data
  await Future.delayed(const Duration(seconds: 1));
  return DashboardStats(
    totalRevenue: 125000.0,
    revenueChange: 12.5,
    totalOrders: 1250,
    ordersChange: 8.3,
    activeUsers: 450,
    usersChange: 15.2,
    averageOrderValue: 100.0,
    aovChange: 5.7,
    revenueData: [
      RevenueData(date: DateTime.now().subtract(const Duration(days: 6)), amount: 15000),
      RevenueData(date: DateTime.now().subtract(const Duration(days: 5)), amount: 18000),
      RevenueData(date: DateTime.now().subtract(const Duration(days: 4)), amount: 22000),
      RevenueData(date: DateTime.now().subtract(const Duration(days: 3)), amount: 19000),
      RevenueData(date: DateTime.now().subtract(const Duration(days: 2)), amount: 25000),
      RevenueData(date: DateTime.now().subtract(const Duration(days: 1)), amount: 28000),
      RevenueData(date: DateTime.now(), amount: 32000),
    ],
    orderTypeDistribution: {
      'dine_in': 450,
      'takeaway': 350,
      'delivery': 450,
    },
    topRestaurants: [
      RestaurantData(name: 'Restaurant A', revenue: 25000, orders: 250),
      RestaurantData(name: 'Restaurant B', revenue: 22000, orders: 220),
      RestaurantData(name: 'Restaurant C', revenue: 20000, orders: 200),
    ],
    recentOrders: [
      OrderData(id: '1', customerName: 'John Doe', amount: 45.50, date: DateTime.now().subtract(const Duration(hours: 1)), status: 'confirmed'),
      OrderData(id: '2', customerName: 'Jane Smith', amount: 32.75, date: DateTime.now().subtract(const Duration(hours: 2)), status: 'preparing'),
      OrderData(id: '3', customerName: 'Bob Johnson', amount: 67.25, date: DateTime.now().subtract(const Duration(hours: 3)), status: 'ready'),
    ],
  );
});
