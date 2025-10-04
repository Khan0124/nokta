import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

import '../../providers/customer_app_providers.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final timeline = ref.watch(orderTimelineProvider(orderId));
    final driverInfo = ref.watch(driverSummaryProvider(orderId));
    final driverRoute = ref.watch(driverRouteProvider(orderId));

    return orderAsync.when(
      data: (order) {
        final currentStage = timeline.maybeWhen(
          data: (update) => update.stage,
          orElse: () => OrderTrackingStage.placed,
        );
        final driverPosition = driverRoute.asData?.value;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.translate('customer.order.appBar', params: {'id': '#${order.id}'})),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => _showSupportDialog(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OrderStatusTimeline(currentStage: currentStage),
              const SizedBox(height: 16),
              OrderTrackingMap(
                driverLat: driverPosition?.latitude,
                driverLng: driverPosition?.longitude,
              ),
              const SizedBox(height: 16),
              OrderDetailsCard(order: order),
              const SizedBox(height: 16),
              driverInfo.when(
                data: (driver) => DriverInfoCard(driver: driver),
                loading: () => const LoadingScreen(),
                error: (error, stack) => ErrorScreen(
                  message: '$error',
                  onRetry: () => ref.refresh(driverSummaryProvider(orderId)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: LoadingScreen()),
      error: (error, stack) => Scaffold(
        body: ErrorScreen(
          message: '$error',
          onRetry: () => ref.refresh(orderDetailProvider(orderId)),
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('customer.order.supportTitle')),
        content: Text(l10n.translate('customer.order.supportBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('customer.common.close')),
          ),
        ],
      ),
    );
  }
}
