import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/offline_order_queue.dart';

final offlineOrderQueueProvider = Provider<OfflineOrderQueue>((ref) {
  throw UnimplementedError(
    'OfflineOrderQueue must be provided via ProviderScope overrides.',
  );
});

final pendingOfflineOrdersProvider = StreamProvider<int>((ref) async* {
  final queue = ref.watch(offlineOrderQueueProvider);
  yield await queue.pendingCount();
  yield* queue.pendingCountStream;
});
