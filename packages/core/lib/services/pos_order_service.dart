import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/order.dart';
import 'offline_order_queue.dart';
import 'order_service.dart';
import 'sync_service.dart';

class OrderSubmissionResult {
  const OrderSubmissionResult({
    required this.order,
    required this.wasQueued,
    required this.wasSynced,
    this.queueId,
    this.error,
  });

  final Order order;
  final bool wasQueued;
  final bool wasSynced;
  final int? queueId;
  final String? error;
}

class PosOrderService {
  PosOrderService({
    required this.orderService,
    required this.queue,
    required this.connectivity,
    required this.syncService,
  });

  final OrderService orderService;
  final OfflineOrderQueue queue;
  final Connectivity connectivity;
  final SyncService syncService;

  Future<OrderSubmissionResult> submit(Order order) async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      final queueId = await queue.enqueue(order);
      return OrderSubmissionResult(
        order: order,
        wasQueued: true,
        wasSynced: false,
        queueId: queueId,
      );
    }

    try {
      final remoteOrder = await orderService.createOrder(order);
      await syncService.triggerImmediateSync();
      return OrderSubmissionResult(
        order: remoteOrder,
        wasQueued: false,
        wasSynced: true,
      );
    } catch (error) {
      final queueId = await queue.enqueue(order);
      await syncService.triggerImmediateSync();
      return OrderSubmissionResult(
        order: order,
        wasQueued: true,
        wasSynced: false,
        queueId: queueId,
        error: error.toString(),
      );
    }
  }
}
