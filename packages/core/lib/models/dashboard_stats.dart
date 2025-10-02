class DashboardStats {
  final double totalRevenue;
  final double revenueChange;
  final int totalOrders;
  final double ordersChange;
  final int activeUsers;
  final double usersChange;
  final double averageOrderValue;
  final double aovChange;
  final List<RevenueData> revenueData;
  final Map<String, int> orderTypeDistribution;
  final List<RestaurantData> topRestaurants;
  final List<OrderData> recentOrders;

  const DashboardStats({
    required this.totalRevenue,
    required this.revenueChange,
    required this.totalOrders,
    required this.ordersChange,
    required this.activeUsers,
    required this.usersChange,
    required this.averageOrderValue,
    required this.aovChange,
    required this.revenueData,
    required this.orderTypeDistribution,
    required this.topRestaurants,
    required this.recentOrders,
  });
}

class RevenueData {
  final DateTime date;
  final double amount;

  const RevenueData({
    required this.date,
    required this.amount,
  });
}

class RestaurantData {
  final String name;
  final double revenue;
  final int orders;

  const RestaurantData({
    required this.name,
    required this.revenue,
    required this.orders,
  });
}

class OrderData {
  final String id;
  final String customerName;
  final double amount;
  final DateTime date;
  final String status;

  const OrderData({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.date,
    required this.status,
  });
}
