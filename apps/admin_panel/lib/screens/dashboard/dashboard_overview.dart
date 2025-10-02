import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

// apps/admin_panel/lib/screens/dashboard/dashboard_overview.dart
class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    
    return stats.when(
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            // KPI Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                KPICard(
                  title: 'Total Revenue',
                  value: formatCurrency(data.totalRevenue),
                  change: data.revenueChange,
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
                KPICard(
                  title: 'Total Orders',
                  value: formatNumber(data.totalOrders),
                  change: data.ordersChange,
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
                KPICard(
                  title: 'Active Users',
                  value: formatNumber(data.activeUsers),
                  change: data.usersChange,
                  icon: Icons.people,
                  color: Colors.orange,
                ),
                KPICard(
                  title: 'Average Order Value',
                  value: formatCurrency(data.averageOrderValue),
                  change: data.aovChange,
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Chart
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Revenue Trend',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: RevenueChart(data: data.revenueData),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Order Distribution
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Types',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: OrderTypePieChart(
                              data: data.orderTypeDistribution,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Tables Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Restaurants
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Restaurants',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          TopRestaurantsTable(
                            restaurants: data.topRestaurants,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Recent Orders
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Orders',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          RecentOrdersList(
                            orders: data.recentOrders,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}