import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/order.dart';
import 'offline_order_queue.dart';
import 'order_service.dart';

enum SyncState { idle, syncing, offline, error }

class SyncStatus {
  const SyncStatus({
    required this.state,
    required this.pendingCount,
    this.lastSyncedAt,
    this.message,
  });

  final SyncState state;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? message;

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? message,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: message ?? this.message,
    );
  }
}

class SyncService {
  SyncService({
    required this.orderService,
    required this.queue,
    Connectivity? connectivity,
    Duration syncInterval = const Duration(seconds: 30),
    int batchSize = 10,
  })  : _connectivity = connectivity ?? Connectivity(),
        _syncInterval = syncInterval,
        _batchSize = batchSize;

  final OrderService orderService;
  final OfflineOrderQueue queue;
  final Connectivity _connectivity;
  final Duration _syncInterval;
  final int _batchSize;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get statusStream => _statusController.stream;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _timer;
  DateTime? _lastSyncedAt;
  bool _isSyncing = false;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _connectivitySubscription ??=
        _connectivity.onConnectivityChanged.listen((event) async {
      if (event == ConnectivityResult.none) {
        final pending = await queue.pendingCount();
        _emitStatus(
          SyncStatus(
            state: SyncState.offline,
            pendingCount: pending,
            lastSyncedAt: _lastSyncedAt,
          ),
        );
      } else {
        await flushPending();
      }
    });

    _timer ??= Timer.periodic(_syncInterval, (_) {
      unawaited(flushPending());
    });

    await flushPending();
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _timer?.cancel();
    await _statusController.close();
  }

  Future<void> flushPending() async {
    if (_isSyncing) return;

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      final pending = await queue.pendingCount();
      _emitStatus(
        SyncStatus(
          state: SyncState.offline,
          pendingCount: pending,
          lastSyncedAt: _lastSyncedAt,
        ),
      );
      return;
    }

    final pendingOrders = await queue.fetchPending(batchSize: _batchSize);
    if (pendingOrders.isEmpty) {
      final pending = await queue.pendingCount();
      _emitStatus(
        SyncStatus(
          state: SyncState.idle,
          pendingCount: pending,
          lastSyncedAt: _lastSyncedAt,
        ),
      );
      return;
    }

    _isSyncing = true;
    _emitStatus(
      SyncStatus(
        state: SyncState.syncing,
        pendingCount: pendingOrders.length,
        lastSyncedAt: _lastSyncedAt,
      ),
    );

    for (final queued in pendingOrders) {
      await _syncQueuedOrder(queued);
    }

    _isSyncing = false;

    final remaining = await queue.pendingCount();
    _emitStatus(
      SyncStatus(
        state: SyncState.idle,
        pendingCount: remaining,
        lastSyncedAt: _lastSyncedAt,
      ),
    );
  }

  Future<void> triggerImmediateSync() async {
    await flushPending();
  }

  Future<void> _syncQueuedOrder(QueuedOrder queued) async {
    try {
      await queue.markSyncing(queued.id);
      await orderService.createOrder(queued.order);
      await queue.markSynced(queued.id);
      _lastSyncedAt = DateTime.now();
      _emitStatus(
        SyncStatus(
          state: SyncState.syncing,
          pendingCount: await queue.pendingCount(),
          lastSyncedAt: _lastSyncedAt,
        ),
      );
    } catch (error) {
      await queue.markFailed(queued.id, error.toString());
      _emitStatus(
        SyncStatus(
          state: SyncState.error,
          pendingCount: await queue.pendingCount(),
          lastSyncedAt: _lastSyncedAt,
          message: error.toString(),
        ),
      );
    }
  }

  void _emitStatus(SyncStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}

void unawaited(Future<void>? future) {
  future?.catchError((_) {});
}
