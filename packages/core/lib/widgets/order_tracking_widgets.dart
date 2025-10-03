import 'package:flutter/material.dart';
import 'package:nokta_core/l10n/app_localizations.dart';
import 'package:nokta_core/models/order.dart';
import 'package:nokta_core/models/order_tracking_update.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.currentStage,
  });

  final OrderTrackingStage currentStage;

  static const _stages = [
    OrderTrackingStage.placed,
    OrderTrackingStage.confirmed,
    OrderTrackingStage.preparing,
    OrderTrackingStage.driverAssigned,
    OrderTrackingStage.onTheWay,
    OrderTrackingStage.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('customer.order.timelineTitle'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ..._stages.map((stage) {
          final index = _stages.indexOf(stage);
          final isCompleted = index <= _stages.indexOf(currentStage);
          final isCurrent = stage == currentStage;
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimelineIcon(stage: stage, isCompleted: isCompleted, isCurrent: isCurrent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stageLabel(stage, l10n),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                        if (isCurrent)
                          Text(
                            l10n.translate('customer.order.inProgress'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.primary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index != _stages.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  String _stageLabel(OrderTrackingStage stage, AppLocalizations l10n) {
    switch (stage) {
      case OrderTrackingStage.placed:
        return l10n.translate('customer.order.status.placed');
      case OrderTrackingStage.confirmed:
        return l10n.translate('customer.order.status.confirmed');
      case OrderTrackingStage.preparing:
        return l10n.translate('customer.order.status.preparing');
      case OrderTrackingStage.driverAssigned:
        return l10n.translate('customer.order.status.driverAssigned');
      case OrderTrackingStage.onTheWay:
        return l10n.translate('customer.order.status.onTheWay');
      case OrderTrackingStage.delivered:
        return l10n.translate('customer.order.status.delivered');
      case OrderTrackingStage.cancelled:
        return l10n.translate('customer.order.status.cancelled');
    }
  }
}

class _TimelineIcon extends StatelessWidget {
  const _TimelineIcon({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
  });

  final OrderTrackingStage stage;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted
            ? Theme.of(context).colorScheme.primary
            : isCurrent
                ? Theme.of(context).colorScheme.secondary
                : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconForStage(stage),
        color: isCompleted || isCurrent
            ? Colors.white
            : Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  IconData _iconForStage(OrderTrackingStage stage) {
    switch (stage) {
      case OrderTrackingStage.placed:
        return Icons.check_circle_outline;
      case OrderTrackingStage.confirmed:
        return Icons.restaurant_menu;
      case OrderTrackingStage.preparing:
        return Icons.kitchen_outlined;
      case OrderTrackingStage.driverAssigned:
        return Icons.delivery_dining;
      case OrderTrackingStage.onTheWay:
        return Icons.map_outlined;
      case OrderTrackingStage.delivered:
        return Icons.home_outlined;
      case OrderTrackingStage.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

class OrderTrackingMap extends StatelessWidget {
  const OrderTrackingMap({
    super.key,
    this.driverLat,
    this.driverLng,
  });

  final double? driverLat;
  final double? driverLng;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(l10n.translate('customer.order.mapPlaceholder')),
            if (driverLat != null && driverLng != null)
              Text(
                '(${driverLat!.toStringAsFixed(4)}, ${driverLng!.toStringAsFixed(4)})',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsCard extends StatelessWidget {
  const OrderDetailsCard({
    super.key,
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('customer.order.detailsTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _detailRow(l10n.translate('customer.order.orderId'), '#${order.id}'),
            _detailRow(
              l10n.translate('customer.order.totalAmount'),
              l10n.formatCurrency(order.total),
            ),
            if (order.deliveryAddress != null)
              _detailRow(
                l10n.translate('customer.order.deliveryAddress'),
                order.deliveryAddress!,
              ),
            _detailRow(
              l10n.translate('customer.order.paymentMethod'),
              order.paymentMethod != null
                  ? order.paymentMethod!.name
                  : l10n.translate('customer.order.paymentPending'),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('customer.order.itemsHeading'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${item.notes ?? '#${item.productId}'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(l10n.formatCurrency(item.totalPrice)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({
    super.key,
    required this.driver,
  });

  final Map<String, dynamic> driver;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('customer.order.driverTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.person),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name'] ?? l10n.translate('customer.order.driverUnknown'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        driver['vehicle'] ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: Text(l10n.translate('customer.order.callDriver')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.translate('customer.order.chatDriver')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message ?? context.l10n.translate('customer.common.loading')),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(l10n.translate('customer.common.retry')),
            ),
          ],
        ],
      ),
    );
  }
}
