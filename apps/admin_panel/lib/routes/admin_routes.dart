import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/analytics/real_time_analytics.dart';
import '../screens/dashboard/admin_dashboard_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const RealTimeAnalyticsScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsManagementScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersManagementScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersManagementScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

// Placeholder screens
class ProductsManagementScreen extends StatelessWidget {
  const ProductsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المنتجات')),
      body: const Center(child: Text('Products Management')),
    );
  }
}

class OrdersManagementScreen extends StatelessWidget {
  const OrdersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلبات')),
      body: const Center(child: Text('Orders Management')),
    );
  }
}

class CustomersManagementScreen extends StatelessWidget {
  const CustomersManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة العملاء')),
      body: const Center(child: Text('Customers Management')),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: const Center(child: Text('Reports')),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: const Center(child: Text('Settings')),
    );
  }
}
