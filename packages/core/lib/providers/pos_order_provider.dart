import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pos_order_service.dart';
import 'connectivity_provider.dart';
import 'offline_queue_provider.dart';
import 'order_service_provider.dart';
import 'sync_provider.dart';

final posOrderServiceProvider = Provider<PosOrderService>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final queue = ref.watch(offlineOrderQueueProvider);
  final connectivity = ref.watch(connectivityProvider);
  final syncService = ref.watch(syncServiceProvider);

  return PosOrderService(
    orderService: orderService,
    queue: queue,
    connectivity: connectivity,
    syncService: syncService,
  );
});
