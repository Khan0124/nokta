import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver_route_point.dart';
import '../models/driver_task.dart';
import '../services/driver_location_tracker.dart';
import '../services/driver_task_service.dart';

final driverTaskServiceProvider = Provider<DriverTaskService>((ref) {
  final service = DriverTaskService();
  ref.onDispose(service.dispose);
  return service;
});

final activeDriverTasksProvider =
    StreamProvider.autoDispose<List<DriverTask>>((ref) {
  final service = ref.watch(driverTaskServiceProvider);
  return service.watchTasks(includeCompleted: false);
});

final driverTaskHistoryProvider =
    StreamProvider.autoDispose<List<DriverTask>>((ref) {
  final service = ref.watch(driverTaskServiceProvider);
  return service.watchTasks(includeCompleted: true);
});

final driverRouteHistoryProvider = StreamProvider.autoDispose
    .family<List<DriverRoutePoint>, String>((ref, taskId) {
  final service = ref.watch(driverTaskServiceProvider);
  return service.watchRoutePoints(taskId);
});

final driverLiveRouteProvider =
    StreamProvider.autoDispose.family<DriverRoutePoint, String>(
        (ref, taskId) {
  final service = ref.watch(driverTaskServiceProvider);
  return service.trackTask(taskId);
});

final driverLocationProvider =
    StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  final tracker = DriverLocationTracker();
  try {
    await tracker.ensurePermissions();
    await for (final point in tracker.trackTask('__driver_presence__')) {
      yield {
        'driverId': point.taskId,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'timestamp': point.recordedAt.toIso8601String(),
        'status': 'active',
        'speedKph': point.speedKph,
        'accuracy': point.accuracy,
      };
    }
  } on PermissionDeniedException {
    yield* Stream.periodic(const Duration(seconds: 30), (tick) {
      return {
        'driverId': '__driver_presence__',
        'latitude': 24.7136 + (tick * 0.0001),
        'longitude': 46.6753 + (tick * 0.0001),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'simulated',
        'speedKph': 0,
        'accuracy': 50,
      };
    });
  } on LocationServiceDisabledException {
    yield {
      'driverId': '__driver_presence__',
      'latitude': 0,
      'longitude': 0,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'location_disabled',
      'speedKph': 0,
      'accuracy': 999,
    };
  }
});

final orderProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(driverTaskServiceProvider);
  final tasks = await service.fetchTasks(includeCompleted: false);
  final nextTask = tasks.isNotEmpty ? tasks.first : null;
  if (nextTask != null) {
    return {
      'id': nextTask.orderId,
      'status': nextTask.status.name,
      'estimatedDelivery':
          nextTask.deliveredAt ?? DateTime.now().add(const Duration(minutes: 30)),
      'driver': {
        'id': nextTask.driverId,
        'name': nextTask.customerName,
        'phone': nextTask.customerPhone,
        'vehicle': 'Assigned vehicle',
      },
    };
  }

  return {
    'id': 'no_task',
    'status': 'idle',
    'estimatedDelivery': DateTime.now().add(const Duration(minutes: 45)),
    'driver': {
      'id': 'unassigned',
      'name': 'No active assignment',
      'phone': '',
      'vehicle': '',
    },
  };
});
