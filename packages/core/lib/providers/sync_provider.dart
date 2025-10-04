import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';
import 'connectivity_provider.dart';
import 'offline_queue_provider.dart';
import 'order_service_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final queue = ref.watch(offlineOrderQueueProvider);
  final connectivity = ref.watch(connectivityProvider);

  final service = SyncService(
    orderService: orderService,
    queue: queue,
    connectivity: connectivity,
  );

  scheduleMicrotask(service.start);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service.statusStream;
});
