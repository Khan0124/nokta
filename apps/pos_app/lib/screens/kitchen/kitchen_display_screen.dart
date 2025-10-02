import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nokta_core/nokta_core.dart';

class KitchenDisplayScreen extends ConsumerStatefulWidget {
  const KitchenDisplayScreen({super.key});

  @override
  ConsumerState<KitchenDisplayScreen> createState() =>
      _KitchenDisplayScreenState();
}

class _KitchenDisplayScreenState extends ConsumerState<KitchenDisplayScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  List<Order> _pendingOrders = [];
  List<Order> _preparingOrders = [];
  List<Order> _readyOrders = [];

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startAutoRefresh();

    // Setup blink animation for urgent orders
    _blinkController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(_blinkController);
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    try {
      final orderService = ref.read(orderServiceProvider);

      // Get orders by status
      final pending = await orderService.getOrders(
        status: OrderStatus.confirmed,
      );
      final preparing = await orderService.getOrders(
        status: OrderStatus.preparing,
      );
      final ready = await orderService.getOrders(
        status: OrderStatus.ready,
        limit: 10,
      );

      setState(() {
        _pendingOrders = pending;
        _preparingOrders = preparing;
        _readyOrders = ready;
      });
    } catch (e) {
      // TODO: Replace with proper logging
      debugPrint('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('شاشة المطبخ'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Timer Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                _getCurrentTime(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Bar
          _buildStatisticsBar(),

          // Orders Grid
          Expanded(
            child: Row(
              children: [
                // Pending Orders
                Expanded(
                  flex: 3,
                  child: _buildOrderColumn(
                    title: 'طلبات جديدة',
                    orders: _pendingOrders,
                    color: Colors.orange,
                    status: OrderStatus.confirmed,
                  ),
                ),

                // Preparing Orders
                Expanded(
                  flex: 3,
                  child: _buildOrderColumn(
                    title: 'قيد التحضير',
                    orders: _preparingOrders,
                    color: Colors.blue,
                    status: OrderStatus.preparing,
                  ),
                ),

                // Ready Orders
                Expanded(
                  flex: 2,
                  child: _buildOrderColumn(
                    title: 'جاهز للتسليم',
                    orders: _readyOrders,
                    color: Colors.green,
                    status: OrderStatus.ready,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar() {
    final totalPending = _pendingOrders.length;
    final totalPreparing = _preparingOrders.length;
    final totalReady = _readyOrders.length;
    final avgPrepTime = _calculateAveragePrepTime();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard('في الانتظار', totalPending.toString(), Colors.orange),
          _buildStatCard('قيد التحضير', totalPreparing.toString(), Colors.blue),
          _buildStatCard('جاهز', totalReady.toString(), Colors.green),
          _buildStatCard('متوسط الوقت', '$avgPrepTime د', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderColumn({
    required String title,
    required List<Order> orders,
    required Color color,
    required OrderStatus status,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 ≈ 13
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لا توجد طلبات',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final isUrgent = _isOrderUrgent(order);

                      return isUrgent
                          ? AnimatedBuilder(
                              animation: _blinkAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _blinkAnimation.value,
                                  child:
                                      _buildOrderCard(order, status, isUrgent),
                                );
                              },
                            )
                          : _buildOrderCard(order, status, isUrgent);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
      Order order, OrderStatus currentStatus, bool isUrgent) {
    final orderTime = _getOrderTime(order);
    final backgroundColor = isUrgent ? Colors.red[50] : Colors.white;
    final borderColor = isUrgent ? Colors.red : Colors.grey[300]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: isUrgent ? 2 : 1),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getOrderTypeColor(order.orderType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${order.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isUrgent ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        orderTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUrgent ? Colors.red : Colors.grey[600],
                          fontWeight:
                              isUrgent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Order Type Badge
              Row(
                children: [
                  _buildOrderTypeBadge(order.orderType),
                ],
              ),

              const Divider(height: 16),

              // Order Items
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product #${item.productId}', // Placeholder since OrderItem doesn't have productName
                                style: const TextStyle(fontSize: 13),
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  item.notes!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (item.modifiers != null &&
                                  item.modifiers!.isNotEmpty)
                                Text(
                                  item.modifiers!.map((m) => m.name).join(', '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const Divider(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.yellow[700]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info,
                        size: 16,
                        color: Colors.yellow[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.yellow[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (currentStatus == OrderStatus.confirmed) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startPreparing(order),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('بدء التحضير'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                  if (currentStatus == OrderStatus.preparing) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsReady(order),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('جاهز'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _addMoreTime(order),
                      icon: const Icon(Icons.add_alarm),
                      color: Colors.orange,
                    ),
                  ],
                  if (currentStatus == OrderStatus.ready) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsDelivered(order),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('تم التسليم'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeBadge(OrderType type) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case OrderType.dineIn:
        icon = Icons.restaurant;
        color = Colors.purple;
        label = 'محلي';
        break;
      case OrderType.takeaway:
        icon = Icons.shopping_bag;
        color = Colors.orange;
        label = 'خارجي';
        break;
      case OrderType.delivery:
        icon = Icons.delivery_dining;
        color = Colors.blue;
        label = 'توصيل';
        break;
      case OrderType.online:
        icon = Icons.phone_android;
        color = Colors.green;
        label = 'اونلاين';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26), // 0.1 * 255 ≈ 26
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Color _getOrderTypeColor(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return Colors.purple;
      case OrderType.takeaway:
        return Colors.orange;
      case OrderType.delivery:
        return Colors.blue;
      case OrderType.online:
        return Colors.green;
    }
  }

  String _getOrderTime(Order order) {
    final now = DateTime.now();
    final orderTime = order.createdAt ?? DateTime.now();
    final difference = now.difference(orderTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} د';
    } else {
      return '${difference.inHours} س';
    }
  }

  bool _isOrderUrgent(Order order) {
    final now = DateTime.now();
    final orderTime = order.createdAt ?? DateTime.now();
    final difference = now.difference(orderTime);

    // Order is urgent if it's been waiting for more than 15 minutes
    return difference.inMinutes > 15;
  }

  int _calculateAveragePrepTime() {
    // Calculate average preparation time from completed orders
    return 20; // Placeholder
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // Action Methods
  void _startPreparing(Order order) async {
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
            order.id,
            OrderStatus.preparing,
          );

      _loadOrders();
      _showSuccessMessage('تم بدء تحضير الطلب');
    } catch (e) {
      _showErrorMessage('فشل في بدء تحضير الطلب');
    }
  }

  void _markAsReady(Order order) async {
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
            order.id,
            OrderStatus.ready,
          );

      _loadOrders();
      _showSuccessMessage('الطلب جاهز للتسليم');
      _playNotificationSound();
    } catch (e) {
      _showErrorMessage('فشل في تحديث حالة الطلب');
    }
  }

  void _markAsDelivered(Order order) async {
    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
            order.id,
            OrderStatus.delivered,
          );

      _loadOrders();
      _showSuccessMessage('تم تسليم الطلب');
    } catch (e) {
      _showErrorMessage('فشل في تحديث حالة الطلب');
    }
  }

  void _addMoreTime(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة وقت'),
        content: const Text('كم دقيقة إضافية تحتاج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('تم إضافة 5 دقائق');
            },
            child: const Text('5 دقائق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('تم إضافة 10 دقائق');
            },
            child: const Text('10 دقائق'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل الطلب #${order.id}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              // Add order details here
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    // Show kitchen settings dialog
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _playNotificationSound() {
    // Play sound when order is ready
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }
}
