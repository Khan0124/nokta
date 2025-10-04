import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../db/local_db.dart';
import '../models/driver_route_point.dart';
import '../models/driver_settlement.dart';
import '../models/driver_task.dart';
import 'driver_location_tracker.dart';

class DriverTaskService {
  DriverTaskService({
    LocalDB? localDB,
    DriverLocationTracker? locationTracker,
  })  : _localDB = localDB ?? LocalDB.instance,
        _locationTracker = locationTracker ?? DriverLocationTracker();

  final LocalDB _localDB;
  final DriverLocationTracker _locationTracker;
  final _tasksController = StreamController<List<DriverTask>>.broadcast();
  final _routeControllers = <String, StreamController<List<DriverRoutePoint>>>{};
  bool _initialized = false;

  Future<Database> get _db async {
    final database = await _localDB.database;
    if (!_initialized) {
      await _ensureTables(database);
      _initialized = true;
    }
    return database;
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS driver_tasks (
        id TEXT PRIMARY KEY,
        driver_id TEXT NOT NULL,
        order_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        dropoff_address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        amount_due REAL NOT NULL,
        currency TEXT NOT NULL,
        status TEXT NOT NULL,
        requires_collection INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        picked_at TEXT,
        en_route_at TEXT,
        delivered_at TEXT,
        cancelled_at TEXT,
        failed_at TEXT,
        payment_method TEXT,
        collected_amount REAL,
        notes TEXT,
        route_snapshot_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS driver_route_points (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        speed_kph REAL NOT NULL,
        accuracy REAL NOT NULL,
        heading REAL,
        interval_seconds INTEGER,
        FOREIGN KEY(task_id) REFERENCES driver_tasks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_driver_route_task ON driver_route_points(task_id)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS driver_settlements (
        id TEXT PRIMARY KEY,
        driver_id TEXT NOT NULL,
        shift_start TEXT NOT NULL,
        shift_end TEXT NOT NULL,
        total_assignments INTEGER NOT NULL,
        completed_assignments INTEGER NOT NULL,
        total_due REAL NOT NULL,
        collected_cash REAL NOT NULL,
        collected_non_cash REAL NOT NULL,
        pending_remittance REAL NOT NULL,
        generated_at TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> dispose() async {
    await _tasksController.close();
    for (final controller in _routeControllers.values) {
      await controller.close();
    }
    _routeControllers.clear();
  }

  Future<List<DriverTask>> fetchTasks({bool includeCompleted = true}) async {
    final database = await _db;
    final whereClause = includeCompleted
        ? '1=1'
        : "status NOT IN ('delivered','failed','cancelled')";
    final rows = await database.query(
      'driver_tasks',
      where: whereClause,
      orderBy: 'created_at DESC',
    );
    return rows.map(DriverTask.fromMap).toList();
  }

  Stream<List<DriverTask>> watchTasks({bool includeCompleted = true}) {
    _emitTasks(includeCompleted: includeCompleted);
    return _tasksController.stream.map((tasks) {
      if (includeCompleted) {
        return tasks;
      }
      return tasks
          .where(
            (task) =>
                task.status != DriverTaskStatus.delivered &&
                task.status != DriverTaskStatus.failed &&
                task.status != DriverTaskStatus.cancelled,
          )
          .toList(growable: false);
    });
  }

  Future<void> _emitTasks({bool includeCompleted = true}) async {
    final tasks = await fetchTasks(includeCompleted: includeCompleted);
    if (!_tasksController.isClosed) {
      _tasksController.add(tasks);
    }
  }

  Future<void> upsertTasks(List<DriverTask> tasks) async {
    final database = await _db;
    final batch = database.batch();
    for (final task in tasks) {
      batch.insert(
        'driver_tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    await _emitTasks();
  }

  Future<DriverTask?> findTask(String taskId) async {
    final database = await _db;
    final rows = await database.query(
      'driver_tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return DriverTask.fromMap(rows.first);
  }

  Future<void> updateStatus(
    String taskId,
    DriverTaskStatus status, {
    DateTime? eventTime,
    double? collectedAmount,
    DriverPaymentMethod? paymentMethod,
    String? notes,
  }) async {
    final database = await _db;
    final updateMap = <String, dynamic>{
      'status': status.name,
    };

    final timestamp = (eventTime ?? DateTime.now()).toIso8601String();
    switch (status) {
      case DriverTaskStatus.pickedUp:
        updateMap['picked_at'] = timestamp;
        break;
      case DriverTaskStatus.enRoute:
        updateMap['en_route_at'] = timestamp;
        break;
      case DriverTaskStatus.delivered:
        updateMap['delivered_at'] = timestamp;
        break;
      case DriverTaskStatus.cancelled:
        updateMap['cancelled_at'] = timestamp;
        break;
      case DriverTaskStatus.failed:
        updateMap['failed_at'] = timestamp;
        break;
      case DriverTaskStatus.assigned:
      case DriverTaskStatus.accepted:
        break;
    }

    if (collectedAmount != null) {
      updateMap['collected_amount'] = collectedAmount;
    }
    if (paymentMethod != null) {
      updateMap['payment_method'] = paymentMethod.name;
    }
    if (notes != null) {
      updateMap['notes'] = notes;
    }

    await database.update(
      'driver_tasks',
      updateMap,
      where: 'id = ?',
      whereArgs: [taskId],
    );
    await _emitTasks();
  }

  Future<void> recordRoutePoint(String taskId, DriverRoutePoint point) async {
    final database = await _db;
    await database.insert(
      'driver_route_points',
      point.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitRoutePoints(taskId);
  }

  Future<void> clearRoutePoints(String taskId) async {
    final database = await _db;
    await database.delete(
      'driver_route_points',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    await _emitRoutePoints(taskId);
  }

  Future<void> _emitRoutePoints(String taskId) async {
    final database = await _db;
    final rows = await database.query(
      'driver_route_points',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'recorded_at ASC',
    );
    final points = rows.map(DriverRoutePoint.fromMap).toList(growable: false);
    final controller = _routeControllers[taskId];
    if (controller != null && !controller.isClosed) {
      controller.add(points);
    }
  }

  Stream<List<DriverRoutePoint>> watchRoutePoints(String taskId) {
    final controller = _routeControllers.putIfAbsent(
      taskId,
      () => StreamController<List<DriverRoutePoint>>.broadcast(
        onListen: () => _emitRoutePoints(taskId),
      ),
    );
    return controller.stream;
  }

  Stream<DriverRoutePoint> trackTask(String taskId) async* {
    await _locationTracker.ensurePermissions();
    await for (final point in _locationTracker.trackTask(taskId)) {
      await recordRoutePoint(taskId, point);
      yield point;
    }
  }

  Future<DriverSettlement> closeShift({
    required String driverId,
    required DateTime shiftStart,
    required DateTime shiftEnd,
    String? notes,
  }) async {
    final database = await _db;
    final rows = await database.query(
      'driver_tasks',
      where: 'driver_id = ? AND created_at BETWEEN ? AND ?',
      whereArgs: [
        driverId,
        shiftStart.toIso8601String(),
        shiftEnd.toIso8601String(),
      ],
    );
    final tasks = rows.map(DriverTask.fromMap).toList();
    final totalDue = tasks.fold<double>(0, (sum, task) => sum + task.amountDue);
    final collectedCash = tasks
        .where((task) => task.paymentMethod == DriverPaymentMethod.cash)
        .fold<double>(0, (sum, task) => sum + (task.collectedAmount ?? 0));
    final collectedNonCash = tasks
        .where((task) =>
            task.paymentMethod != null &&
            task.paymentMethod != DriverPaymentMethod.cash)
        .fold<double>(0, (sum, task) => sum + (task.collectedAmount ?? 0));
    final pendingRemittance = collectedCash;

    final settlement = DriverSettlement(
      id: const Uuid().v4(),
      driverId: driverId,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      totalAssignments: tasks.length,
      completedAssignments:
          tasks.where((task) => task.status == DriverTaskStatus.delivered).length,
      totalDue: totalDue,
      collectedCash: collectedCash,
      collectedNonCash: collectedNonCash,
      pendingRemittance: pendingRemittance,
      generatedAt: DateTime.now(),
      notes: notes,
    );

    await database.insert(
      'driver_settlements',
      settlement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return settlement;
  }
}
