import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_center_metrics.dart';
import '../models/call_center_queue_entry.dart';
import '../services/call_center_service.dart';
import 'dio_provider.dart';

final callCenterServiceProvider = Provider<CallCenterService>((ref) {
  final dio = ref.watch(dioProvider);
  final service = CallCenterService(dio);
  ref.onDispose(service.dispose);
  return service;
});

final callQueueProvider = StreamProvider<List<CallCenterQueueEntry>>((ref) {
  final service = ref.watch(callCenterServiceProvider);
  return service.watchQueue();
});

final callCenterMetricsProvider = StreamProvider<CallCenterMetrics>((ref) {
  final service = ref.watch(callCenterServiceProvider);
  return service.watchMetrics();
});

final callCenterCustomerLookupProvider = FutureProvider.family.autoDispose((
  Ref ref,
  String query,
) {
  final service = ref.watch(callCenterServiceProvider);
  return service.lookupCustomer(query);
});
