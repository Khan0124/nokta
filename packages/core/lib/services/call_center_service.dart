import 'dart:async';

import 'package:dio/dio.dart';

import '../models/call_center_metrics.dart';
import '../models/call_center_queue_entry.dart';
import '../models/customer_loyalty.dart';

class CallCenterOrderResult {
  const CallCenterOrderResult({
    required this.reference,
    required this.total,
    required this.persisted,
  });

  factory CallCenterOrderResult.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>?;
    final totalAmount = totals?['total'] is num ? (totals!['total'] as num).toDouble() : 0;
    final reference = json['orderNumber']?.toString() ?? json['orderId']?.toString() ?? json['id']?.toString() ?? 'N/A';
    return CallCenterOrderResult(
      reference: reference,
      total: totalAmount,
      persisted: json['persisted']?.toString() ?? 'unknown',
    );
  }

  final String reference;
  final double total;
  final String persisted;
}

class CallCenterService {
  CallCenterService(
    this._dio, {
    DateTime Function()? clock,
    Duration queuePollInterval = const Duration(seconds: 5),
    Duration metricsPollInterval = const Duration(seconds: 15),
  })  : _clock = clock ?? DateTime.now,
        _queuePollInterval = queuePollInterval,
        _metricsPollInterval = metricsPollInterval {
    _queueController = StreamController<List<CallCenterQueueEntry>>.broadcast(
      onListen: () {
        if (_queue.isNotEmpty) {
          _queueController.add(List.unmodifiable(_queue));
        }
        _queueTimer ??= Timer.periodic(_queuePollInterval, (_) => refreshQueue());
        unawaited(refreshQueue());
      },
      onCancel: () {
        if (!_queueController.hasListener) {
          _queueTimer?.cancel();
          _queueTimer = null;
        }
      },
    );

    _metricsController = StreamController<CallCenterMetrics>.broadcast(
      onListen: () {
        if (_metrics != null) {
          _metricsController.add(_metrics!);
        }
        _metricsTimer ??= Timer.periodic(_metricsPollInterval, (_) => refreshMetrics());
        unawaited(refreshMetrics());
      },
      onCancel: () {
        if (!_metricsController.hasListener) {
          _metricsTimer?.cancel();
          _metricsTimer = null;
        }
      },
    );
  }

  final Dio _dio;
  final DateTime Function() _clock;
  final Duration _queuePollInterval;
  final Duration _metricsPollInterval;

  late final StreamController<List<CallCenterQueueEntry>> _queueController;
  late final StreamController<CallCenterMetrics> _metricsController;

  final List<CallCenterQueueEntry> _queue = <CallCenterQueueEntry>[];
  CallCenterMetrics? _metrics;
  Timer? _queueTimer;
  Timer? _metricsTimer;

  Stream<List<CallCenterQueueEntry>> watchQueue() => _queueController.stream;

  Stream<CallCenterMetrics> watchMetrics() => _metricsController.stream;

  Future<List<CallCenterQueueEntry>> fetchQueue({String? tenantId}) async {
    final response = await _dio.get('/call-center/queue', queryParameters: {
      if (tenantId != null) 'tenantId': tenantId,
    });

    final results = (response.data['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CallCenterQueueEntry.fromJson)
        .toList(growable: false);

    return results;
  }

  Future<CallCenterMetrics> fetchMetrics({
    String? tenantId,
    String range = 'today',
    int? branchId,
  }) async {
    final response = await _dio.get('/call-center/dashboard', queryParameters: {
      'range': range,
      if (tenantId != null) 'tenantId': tenantId,
      if (branchId != null) 'branchId': branchId,
    });

    return CallCenterMetrics.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> refreshQueue({String? tenantId}) async {
    try {
      final queue = await fetchQueue(tenantId: tenantId);
      _queue
        ..clear()
        ..addAll(queue);
      if (!_queueController.isClosed) {
        _queueController.add(List.unmodifiable(_queue));
      }
    } catch (error, stackTrace) {
      if (!_queueController.isClosed) {
        _queueController.addError(error, stackTrace);
      }
    }
  }

  Future<void> refreshMetrics({String? tenantId, String range = 'today', int? branchId}) async {
    try {
      final metrics = await fetchMetrics(tenantId: tenantId, range: range, branchId: branchId);
      _metrics = metrics;
      if (!_metricsController.isClosed) {
        _metricsController.add(metrics);
      }
    } catch (error, stackTrace) {
      if (!_metricsController.isClosed) {
        _metricsController.addError(error, stackTrace);
      }
    }
  }

  Future<CustomerLoyaltyProfile?> lookupCustomer(String input) async {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final response = await _dio.get('/call-center/customers/search', queryParameters: {
      'q': normalized,
      'limit': 1,
      'includeHistory': true,
    });

    final results = (response.data['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    if (results.isEmpty) {
      return null;
    }

    return CustomerLoyaltyProfile.fromJson(results.first);
  }

  Future<CallCenterOrderResult> createGuidedOrder({
    required CallCenterQueueEntry entry,
    int? branchId,
    String channel = 'call_center',
    List<Map<String, dynamic>>? items,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? delivery,
    Map<String, dynamic>? metadata,
    String? tenantId,
  }) async {
    final defaultItems = items ??
        [
          {
            'productId': entry.customerId ?? 0,
            'name': 'Guided Order Placeholder',
            'quantity': 1,
            'unitPrice': 50,
            'discount': 0,
            'modifiers': const <Map<String, dynamic>>[],
            'notes': entry.notes,
          }
        ];

    final defaultPayment = payment ??
        {
          'method': 'cash',
          'status': 'pending',
          'amountDue': defaultItems.fold<double>(0, (sum, item) {
            final price = item['unitPrice'] is num ? (item['unitPrice'] as num).toDouble() : 0;
            final quantity = item['quantity'] is num ? (item['quantity'] as num).toDouble() : 1;
            final discount = item['discount'] is num ? (item['discount'] as num).toDouble() : 0;
            return sum + (price * quantity) - discount;
          }),
          'tipAmount': 0,
          'collectOnDelivery': true,
        };

    final defaultDelivery = delivery ??
        {
          'type': 'delivery',
          'city': null,
          'addressLine1': null,
          'notes': entry.notes,
        };

    final defaultMetadata = metadata ??
        {
          'notes': entry.notes,
          'channel': channel,
          'priority': entry.priority >= 90 ? 'vip' : entry.priority >= 75 ? 'high' : 'normal',
          'source': channel,
        };

    final body = {
      'customer': {
        'id': entry.customerId,
        'fullName': entry.displayName,
        'phone': entry.callerNumber,
        'notes': entry.notes,
      },
      'items': defaultItems,
      'delivery': defaultDelivery,
      'payment': defaultPayment,
      'metadata': defaultMetadata,
      if (branchId != null) 'branchId': branchId,
      if (tenantId != null) 'tenantId': tenantId,
      'campaignCode': null,
      'callId': entry.id,
    };

    final response = await _dio.post('/call-center/orders', data: body);

    unawaited(refreshQueue(tenantId: tenantId));
    unawaited(refreshMetrics(tenantId: tenantId));

    return CallCenterOrderResult.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  void dispose() {
    _queueTimer?.cancel();
    _metricsTimer?.cancel();
    _queueController.close();
    _metricsController.close();
  }
}
