import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/order.dart';

enum OfflineOrderStatus { pending, syncing, failed, synced }

class QueuedOrder {
  QueuedOrder({
    required this.id,
    required this.order,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.lastError,
  });

  final int id;
  final Order order;
  final OfflineOrderStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final String? lastError;

  QueuedOrder copyWith({
    OfflineOrderStatus? status,
    int? retryCount,
    DateTime? updatedAt,
    DateTime? syncedAt,
    String? lastError,
  }) {
    return QueuedOrder(
      id: id,
      order: order,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      lastError: lastError ?? this.lastError,
    );
  }
}

class OfflineOrderQueue {
  OfflineOrderQueue._(this._database);

  static const _tableName = 'offline_orders';
  static const _databaseName = 'nokta_offline_queue.db';

  final Database _database;
  bool _isClosed = false;
  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  static Future<OfflineOrderQueue> create() async {
    final path = await getDatabasesPath();
    final databasePath = p.join(path, _databaseName);

    final database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_payload TEXT NOT NULL,
            status TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            synced_at TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_offline_orders_status ON $_tableName(status)');
      },
    );

    final queue = OfflineOrderQueue._(database);
    await queue._emitPendingCount();
    return queue;
  }

  Future<int> enqueue(Order order) async {
    final now = DateTime.now().toUtc();
    final id = await _database.insert(
      _tableName,
      {
        'order_payload': jsonEncode(order.toMap()),
        'status': OfflineOrderStatus.pending.name,
        'retry_count': 0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitPendingCount();
    return id;
  }

  Future<List<QueuedOrder>> fetchPending({int batchSize = 20}) async {
    final results = await _database.query(
      _tableName,
      where: 'status IN (?, ?, ?)',
      whereArgs: [
        OfflineOrderStatus.pending.name,
        OfflineOrderStatus.syncing.name,
        OfflineOrderStatus.failed.name,
      ],
      orderBy: 'created_at ASC',
      limit: batchSize,
    );

    return results.map(_mapToQueuedOrder).toList();
  }

  Future<int> pendingCount() async {
    final result = Sqflite.firstIntValue(await _database.rawQuery(
      'SELECT COUNT(*) FROM $_tableName WHERE status IN (?, ?, ?)',
      [
        OfflineOrderStatus.pending.name,
        OfflineOrderStatus.syncing.name,
        OfflineOrderStatus.failed.name,
      ],
    ));
    return result ?? 0;
  }

  Future<void> markSyncing(int id) async {
    final now = DateTime.now().toUtc();
    await _database.update(
      _tableName,
      {
        'status': OfflineOrderStatus.syncing.name,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _emitPendingCount();
  }

  Future<void> markSynced(int id) async {
    final now = DateTime.now().toUtc();
    await _database.update(
      _tableName,
      {
        'status': OfflineOrderStatus.synced.name,
        'updated_at': now.toIso8601String(),
        'synced_at': now.toIso8601String(),
        'last_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _emitPendingCount();
  }

  Future<void> markFailed(int id, String errorMessage) async {
    final now = DateTime.now().toUtc();
    await _database.rawUpdate(
      '''
      UPDATE $_tableName
      SET status = ?, retry_count = retry_count + 1, last_error = ?, updated_at = ?
      WHERE id = ?
      ''',
      [
        OfflineOrderStatus.failed.name,
        errorMessage,
        now.toIso8601String(),
        id,
      ],
    );
    await _emitPendingCount();
  }

  Future<void> resetToPending(int id) async {
    final now = DateTime.now().toUtc();
    await _database.update(
      _tableName,
      {
        'status': OfflineOrderStatus.pending.name,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await _emitPendingCount();
  }

  Future<void> purgeSynced({Duration? olderThan}) async {
    final where = olderThan != null ? 'synced_at <= ?' : null;
    final whereArgs = olderThan != null
        ? [DateTime.now().toUtc().subtract(olderThan).toIso8601String()]
        : null;
    await _database.delete(
      _tableName,
      where: where != null ? 'status = ? AND $where' : 'status = ?',
      whereArgs: whereArgs != null
          ? [OfflineOrderStatus.synced.name, ...whereArgs]
          : [OfflineOrderStatus.synced.name],
    );
  }

  Future<void> clearFailed({int? maxRetry}) async {
    final buffer = StringBuffer('status = ?');
    final args = <Object?>[OfflineOrderStatus.failed.name];
    if (maxRetry != null) {
      buffer.write(' AND retry_count >= ?');
      args.add(maxRetry);
    }
    await _database.delete(
      _tableName,
      where: buffer.toString(),
      whereArgs: args,
    );
    await _emitPendingCount();
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _pendingCountController.close();
    await _database.close();
  }

  QueuedOrder _mapToQueuedOrder(Map<String, Object?> map) {
    final statusString = map['status'] as String;
    final status = OfflineOrderStatus.values.firstWhere(
      (element) => element.name == statusString,
      orElse: () => OfflineOrderStatus.pending,
    );

    final payload = jsonDecode(map['order_payload'] as String)
        as Map<String, dynamic>;

    return QueuedOrder(
      id: map['id'] as int,
      order: Order.fromMap(payload),
      status: status,
      retryCount: map['retry_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncedAt: map['synced_at'] != null
          ? DateTime.tryParse(map['synced_at'] as String)
          : null,
      lastError: map['last_error'] as String?,
    );
  }

  Future<void> _emitPendingCount() async {
    if (_pendingCountController.isClosed) {
      return;
    }
    final count = await pendingCount();
    _pendingCountController.add(count);
  }
}
