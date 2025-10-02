import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/dio_provider.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  // Create a new order
  Future<Order> createOrder(Order order) async {
    try {
      final response = await _dio.post('/orders', data: order.toMap());

      if (response.statusCode == 201) {
        final localOrder = order.copyWith(id: response.data['id'] as int);
        return localOrder;
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // Get order by ID
  Future<Order> getOrder(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to load order');
      }
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  // Get all orders for a tenant/branch
  Future<List<Order>> getOrders({
    int? tenantId,
    int? branchId,
    int? customerId,
    OrderStatus? status,
    OrderType? orderType,
    DateTime? fromDate,
    DateTime? toDate,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;
      if (branchId != null) queryParams['branch_id'] = branchId;
      if (customerId != null) queryParams['customer_id'] = customerId;
      if (status != null) queryParams['status'] = status.name;
      if (orderType != null) queryParams['order_type'] = orderType.name;
      if (fromDate != null)
        queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dio.get('/orders', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Order.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  // Update order status
  Future<Order> updateOrderStatus(int orderId, OrderStatus status) async {
    try {
      final response = await _dio.patch(
        '/orders/$orderId/status',
        data: {'status': status.name},
      );

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  // Update order
  Future<Order> updateOrder(int orderId, Order order) async {
    try {
      final response = await _dio.put(
        '/orders/$orderId',
        data: order.toMap(),
      );

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to update order');
      }
    } catch (e) {
      throw Exception('Error updating order: $e');
    }
  }

  // Delete order
  Future<void> deleteOrder(int orderId) async {
    try {
      final response = await _dio.delete('/orders/$orderId');

      if (response.statusCode != 204) {
        throw Exception('Failed to delete order');
      }
    } catch (e) {
      throw Exception('Error deleting order: $e');
    }
  }

  // Get orders by customer
  Future<List<Order>> getCustomerOrders(int customerId) async {
    try {
      final response = await _dio.get('/customers/$customerId/orders');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Order.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load customer orders');
      }
    } catch (e) {
      throw Exception('Error fetching customer orders: $e');
    }
  }

  // Get orders by driver
  Future<List<Order>> getDriverOrders(int driverId) async {
    try {
      final response = await _dio.get('/drivers/$driverId/orders');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Order.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load driver orders');
      }
    } catch (e) {
      throw Exception('Error fetching driver orders: $e');
    }
  }

  // Assign driver to order
  Future<Order> assignDriver(int orderId, int driverId) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/assign-driver',
        data: {'driver_id': driverId},
      );

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to assign driver');
      }
    } catch (e) {
      throw Exception('Error assigning driver: $e');
    }
  }

  // Update order payment status
  Future<Order> updatePaymentStatus(int orderId, PaymentStatus status) async {
    try {
      final response = await _dio.patch(
        '/orders/$orderId/payment-status',
        data: {'payment_status': status.name},
      );

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }

  // Get order analytics
  Future<Map<String, dynamic>> getOrderAnalytics({
    int? tenantId,
    int? branchId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;
      if (branchId != null) queryParams['branch_id'] = branchId;
      if (fromDate != null)
        queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response =
          await _dio.get('/orders/analytics', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load order analytics');
      }
    } catch (e) {
      throw Exception('Error fetching order analytics: $e');
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics({
    int? tenantId,
    int? branchId,
    String? period,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;
      if (branchId != null) queryParams['branch_id'] = branchId;
      if (period != null) queryParams['period'] = period;

      final response =
          await _dio.get('/orders/statistics', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load order statistics');
      }
    } catch (e) {
      throw Exception('Error fetching order statistics: $e');
    }
  }

  // Bulk update orders
  Future<void> bulkUpdateOrders(List<Map<String, dynamic>> updates) async {
    try {
      final response =
          await _dio.put('/orders/bulk', data: {'updates': updates});

      if (response.statusCode != 200) {
        throw Exception('Failed to bulk update orders');
      }
    } catch (e) {
      throw Exception('Error bulk updating orders: $e');
    }
  }

  // Export orders
  Future<String> exportOrders({
    int? tenantId,
    int? branchId,
    DateTime? fromDate,
    DateTime? toDate,
    String format = 'csv',
  }) async {
    try {
      final queryParams = <String, dynamic>{'format': format};
      if (tenantId != null) queryParams['tenant_id'] = tenantId;
      if (branchId != null) queryParams['branch_id'] = branchId;
      if (fromDate != null)
        queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response =
          await _dio.get('/orders/export', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data['download_url'] ?? '';
      } else {
        throw Exception('Failed to export orders');
      }
    } catch (e) {
      throw Exception('Error exporting orders: $e');
    }
  }

  // Sync orders with server
  Future<void> syncOrders(List<Order> orders) async {
    try {
      for (final order in orders) {
        try {
          final response = await _dio.post('/orders/sync', data: order.toMap());

          if (response.statusCode != 200) {
            print(
                'Failed to sync order ${order.id}: ${response.statusMessage}');
          }
        } catch (e) {
          print('Error syncing order ${order.id}: $e');
        }
      }
    } catch (e) {
      throw Exception('Error syncing orders: $e');
    }
  }

  // Get order history
  Future<List<Order>> getOrderHistory(int customerId) async {
    try {
      final response = await _dio.get('/customers/$customerId/order-history');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => Order.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load order history');
      }
    } catch (e) {
      throw Exception('Error fetching order history: $e');
    }
  }

  // Cancel order
  Future<Order> cancelOrder(int orderId, String reason) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/cancel',
        data: {'reason': reason},
      );

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error cancelling order: $e');
    }
  }

  // Refund order
  Future<Order> refundOrder(int orderId, double amount, String reason) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/refund',
        data: {
          'amount': amount,
          'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return Order.fromMap(response.data);
      } else {
        throw Exception('Failed to refund order');
      }
    } catch (e) {
      throw Exception('Error refunding order: $e');
    }
  }

  // Get order timeline
  Future<List<Map<String, dynamic>>> getOrderTimeline(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/timeline');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load order timeline');
      }
    } catch (e) {
      throw Exception('Error fetching order timeline: $e');
    }
  }

  // Add order note
  Future<void> addOrderNote(int orderId, String note) async {
    try {
      final response = await _dio.post(
        '/orders/$orderId/notes',
        data: {'note': note},
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add order note');
      }
    } catch (e) {
      throw Exception('Error adding order note: $e');
    }
  }

  // Get order notes
  Future<List<Map<String, dynamic>>> getOrderNotes(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/notes');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load order notes');
      }
    } catch (e) {
      throw Exception('Error fetching order notes: $e');
    }
  }
}

// Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderService(dio);
});
