// apps/customer_app/lib/screens/order/order_tracking_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  StreamSubscription? _orderSubscription;
  StreamSubscription? _driverLocationSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToOrderUpdates();
  }

  void _subscribeToOrderUpdates() {
    final realtimeService = ref.read(realtimeServiceProvider);
    realtimeService.connectToOrder(widget.orderId.toString());

    _orderSubscription = realtimeService
        .getOrderUpdates(widget.orderId.toString())
        .listen((update) {
      // TODO: Update order state
      print('Order update: $update');
    });
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text('Contact support for help with your order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider);
    final driverLocationAsync = ref.watch(driverLocationProvider);

    return orderAsync.when(
      data: (order) => Scaffold(
        appBar: AppBar(
          title: Text('Order #${order['id']}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help),
              onPressed: () => _showSupportDialog(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Order Status Timeline
            OrderStatusTimeline(
              currentStatus: order['status'] ?? 'preparing',
            ),

            // Map (for delivery orders)
            if (order['type'] == 'delivery')
              Expanded(
                child: OrderTrackingMap(
                  driverLat: driverLocationAsync.value?['latitude'],
                  driverLng: driverLocationAsync.value?['longitude'],
                ),
              ),

            // Order Details
            OrderDetailsCard(order: order),

            // Driver Info (if assigned)
            if (order['driver'] != null)
              DriverInfoCard(
                driver: order['driver']!,
              ),
          ],
        ),
      ),
      loading: () => const LoadingScreen(),
      error: (error, stack) => ErrorScreen(
        message: 'Error loading order: $error',
        onRetry: () => ref.refresh(orderProvider),
      ),
    );
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    super.dispose();
  }
}
