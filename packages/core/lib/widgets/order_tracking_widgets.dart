import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {
        'status': 'confirmed',
        'title': 'Order Confirmed',
        'icon': Icons.check_circle
      },
      {'status': 'preparing', 'title': 'Preparing', 'icon': Icons.restaurant},
      {'status': 'ready', 'title': 'Ready for Pickup', 'icon': Icons.done_all},
      {
        'status': 'on_way',
        'title': 'On the Way',
        'icon': Icons.delivery_dining
      },
      {'status': 'delivered', 'title': 'Delivered', 'icon': Icons.home},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Progress',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        ...statuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final statusString = status['status'] as String;
          final isCompleted = _isStatusCompleted(statusString);
          final isCurrent = statusString == currentStatus;

          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? Colors.orange
                          : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status['icon'] as IconData,
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (status['title'] as String?) ?? 'Unknown',
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrent ? Colors.orange : null,
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'Current Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
              if (index < statuses.length - 1)
                Container(
                  width: 2,
                  height: 30,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  bool _isStatusCompleted(String status) {
    final statusOrder = [
      'confirmed',
      'preparing',
      'ready',
      'on_way',
      'delivered'
    ];
    final currentIndex = statusOrder.indexOf(currentStatus);
    final statusIndex = statusOrder.indexOf(status);
    return statusIndex <= currentIndex;
  }
}

class OrderTrackingMap extends StatelessWidget {
  final double? driverLat;
  final double? driverLng;
  final double? destinationLat;
  final double? destinationLng;

  const OrderTrackingMap({
    super.key,
    this.driverLat,
    this.driverLng,
    this.destinationLat,
    this.destinationLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Map View',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Driver location tracking',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailsCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Order ID', order['id'] ?? 'N/A'),
            _buildDetailRow('Status', order['status'] ?? 'N/A'),
            if (order['estimatedDelivery'] != null)
              _buildDetailRow(
                'Estimated Delivery',
                _formatDateTime(order['estimatedDelivery']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime is String) {
      return DateTime.parse(dateTime).toString().substring(0, 16);
    }
    return dateTime.toString().substring(0, 16);
  }
}

class DriverInfoCard extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverInfoCard({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver['name'] ?? 'Driver Name',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        driver['vehicle'] ?? 'Vehicle Info',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callDriver(driver['phone']),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openChat(driver['id']),
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callDriver(String? phone) {
    // TODO: Implement phone call functionality
    print('Calling driver: $phone');
  }

  void _openChat(String? driverId) {
    // TODO: Implement chat functionality
    print('Opening chat with driver: $driverId');
  }
}

class LoadingScreen extends StatelessWidget {
  final String message;

  const LoadingScreen({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
