import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nokta_core/nokta_core.dart';

import '../navigation/order_navigation_screen.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  int _selectedIndex = 0;
  bool _shiftStarted = false;
  DateTime? _shiftStart;
  Duration _elapsed = Duration.zero;
  Timer? _shiftTimer;

  @override
  void dispose() {
    _shiftTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTasks = ref.watch(activeDriverTasksProvider);
    final taskHistory = ref.watch(driverTaskHistoryProvider);
    final locationAsync = ref.watch(driverLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(activeDriverTasksProvider);
              ref.invalidate(driverTaskHistoryProvider);
            },
          ),
        ],
      ),
      body: _buildBody(activeTasks, taskHistory, locationAsync),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Stats',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<List<DriverTask>> activeTasks,
    AsyncValue<List<DriverTask>> taskHistory,
    AsyncValue<Map<String, dynamic>> locationAsync,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(activeTasks, taskHistory, locationAsync);
      case 1:
        return _buildOrdersTab(activeTasks);
      case 2:
        return _buildRoutesTab(activeTasks);
      case 3:
        return _buildStatsTab(taskHistory);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeTab(
    AsyncValue<List<DriverTask>> activeTasks,
    AsyncValue<List<DriverTask>> history,
    AsyncValue<Map<String, dynamic>> locationAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeDriverTasksProvider);
        ref.invalidate(driverTaskHistoryProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildShiftCard(),
          const SizedBox(height: 16),
          _buildLocationCard(locationAsync),
          const SizedBox(height: 16),
          _buildMetricsRow(activeTasks, history),
          const SizedBox(height: 16),
          _buildRecentAssignments(activeTasks),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(AsyncValue<List<DriverTask>> activeTasks) {
    return activeTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(
            child: Text('No active deliveries at the moment.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
        );
      },
      error: (error, stackTrace) => _ErrorView(
        message: 'Unable to load orders',
        details: error.toString(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRoutesTab(AsyncValue<List<DriverTask>> activeTasks) {
    return activeTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(
            child: Text('Assign a delivery to start route tracking.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _RouteCard(task: tasks[index]),
        );
      },
      error: (error, stackTrace) => _ErrorView(
        message: 'Unable to load route history',
        details: error.toString(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildStatsTab(AsyncValue<List<DriverTask>> taskHistory) {
    return taskHistory.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(
            child: Text('Start your first shift to generate performance data.'),
          );
        }

        final completed = tasks
            .where((task) => task.status == DriverTaskStatus.delivered)
            .toList();
        final completionRate = tasks.isEmpty
            ? 0
            : (completed.length / tasks.length * 100).round();
        final cashCollected = tasks
            .where((task) =>
                task.paymentMethod == DriverPaymentMethod.cash &&
                task.collectedAmount != null)
            .fold<double>(0, (sum, task) => sum + (task.collectedAmount ?? 0));
        final nonCashCollected = tasks
            .where((task) =>
                task.paymentMethod != null &&
                task.paymentMethod != DriverPaymentMethod.cash)
            .fold<double>(0, (sum, task) => sum + (task.collectedAmount ?? 0));
        final pendingRemittance = tasks
            .where((task) =>
                task.requiresCollection &&
                (task.collectedAmount ?? 0) < task.amountDue)
            .fold<double>(0, (sum, task) =>
                sum + (task.amountDue - (task.collectedAmount ?? 0)));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatTile(
              label: 'Deliveries completed',
              value: '${completed.length}',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatTile(
              label: 'Completion rate',
              value: '$completionRate%',
              icon: Icons.percent,
              color: Colors.blue,
            ),
            _StatTile(
              label: 'Cash collected',
              value: _formatCurrency(cashCollected),
              icon: Icons.payments,
              color: Colors.orange,
            ),
            _StatTile(
              label: 'Digital payments',
              value: _formatCurrency(nonCashCollected),
              icon: Icons.credit_card,
              color: Colors.indigo,
            ),
            _StatTile(
              label: 'Cash to remit',
              value: _formatCurrency(pendingRemittance),
              icon: Icons.account_balance_wallet,
              color: Colors.deepPurple,
            ),
          ],
        );
      },
      error: (error, stackTrace) => _ErrorView(
        message: 'Unable to load stats',
        details: error.toString(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildShiftCard() {
    final formatter = DateFormat.Hm();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shiftStarted ? 'Shift in progress' : 'Shift paused',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shiftStarted && _shiftStart != null
                          ? 'Started at ${formatter.format(_shiftStart!)}'
                          : 'Press start to begin tracking',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                FilledButton.icon(
                  icon: Icon(_shiftStarted ? Icons.stop : Icons.play_arrow),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _shiftStarted ? Colors.redAccent : Colors.green,
                  ),
                  onPressed: () {
                    if (_shiftStarted) {
                      _endShift();
                    } else {
                      _startShift();
                    }
                  },
                  label: Text(_shiftStarted ? 'End shift' : 'Start shift'),
                ),
              ],
            ),
            if (_shiftStarted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Elapsed time: ${_formatDuration(_elapsed)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(AsyncValue<Map<String, dynamic>> locationAsync) {
    return locationAsync.when(
      data: (location) {
        final status = location['status'] as String? ?? 'unknown';
        return Card(
          color: status == 'active'
              ? Colors.green.shade50
              : Colors.orange.shade50,
          child: ListTile(
            leading: Icon(
              Icons.my_location,
              color: status == 'active' ? Colors.green : Colors.orange,
            ),
            title: Text(
              status == 'active'
                  ? 'GPS tracking active'
                  : status == 'location_disabled'
                      ? 'Location disabled'
                      : 'Simulated location feed',
            ),
            subtitle: Text(
              'Lat ${location['latitude']?.toStringAsFixed(5)} · Lng ${location['longitude']?.toStringAsFixed(5)}',
            ),
            trailing: Text(
              DateFormat.Hms().format(DateTime.parse(location['timestamp'] as String)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
      error: (error, stackTrace) => Card(
        color: Colors.red.shade50,
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: const Text('Location unavailable'),
          subtitle: Text(error.toString()),
        ),
      ),
      loading: () => const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Initializing GPS tracking…'),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(
    AsyncValue<List<DriverTask>> activeTasks,
    AsyncValue<List<DriverTask>> history,
  ) {
    final active = activeTasks.asData?.value ?? [];
    final deliveredToday = history.asData?.value
            .where((task) =>
                task.status == DriverTaskStatus.delivered &&
                task.deliveredAt != null &&
                _isSameDay(task.deliveredAt!, DateTime.now()))
            .length ??
        0;
    final cashToCollect = active
        .where((task) => task.requiresCollection)
        .fold<double>(0, (sum, task) =>
            sum + (task.amountDue - (task.collectedAmount ?? 0)));

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Active tasks',
            value: '${active.length}',
            icon: Icons.local_shipping,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Delivered today',
            value: '$deliveredToday',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Cash pending',
            value: _formatCurrency(cashToCollect),
            icon: Icons.payments,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAssignments(AsyncValue<List<DriverTask>> activeTasks) {
    return activeTasks.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        final recent = tasks.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s queue',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...recent.map((task) => _RecentTaskTile(task: task)),
          ],
        );
      },
      error: (error, stackTrace) => _ErrorView(
        message: 'Unable to load assignments',
        details: error.toString(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildTaskCard(DriverTask task) {
    final statuses = [
      DriverTaskStatus.assigned,
      DriverTaskStatus.accepted,
      DriverTaskStatus.pickedUp,
      DriverTaskStatus.enRoute,
      DriverTaskStatus.delivered,
    ];
    final currentIndex = statuses.indexOf(task.status).clamp(0, statuses.length - 1);
    final nextStatus = _nextStatus(task.status);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${task.orderId}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.customerName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(task.status.name.toUpperCase()),
                  backgroundColor: Colors.blue.shade50,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.dropoffAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < statuses.length; i++)
                  Chip(
                    avatar: Icon(
                      i <= currentIndex
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: i <= currentIndex ? Colors.green : Colors.grey,
                    ),
                    label: Text(statuses[i].name),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Amount due: ${task.formattedAmountDue}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (task.requiresCollection)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: const Text('Collect on delivery'),
                      backgroundColor: Colors.orange.shade50,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ButtonBar(
              alignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openNavigation(task),
                  icon: const Icon(Icons.route),
                  label: const Text('Navigate'),
                ),
                if (nextStatus != null)
                  FilledButton(
                    onPressed: () => _advanceTask(task),
                    child: Text(_statusActionLabel(task.status)),
                  ),
                if (task.status != DriverTaskStatus.delivered &&
                    task.status != DriverTaskStatus.failed &&
                    task.status != DriverTaskStatus.cancelled)
                  TextButton(
                    onPressed: () => _reportIssue(task),
                    child: const Text('Report issue'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNavigation(DriverTask task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderNavigationScreen(task: task),
      ),
    );
  }

  void _startShift() {
    setState(() {
      _shiftStarted = true;
      _shiftStart = DateTime.now();
      _elapsed = Duration.zero;
    });
    _shiftTimer?.cancel();
    _shiftTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_shiftStart!);
      });
    });
  }

  Future<void> _endShift() async {
    if (!_shiftStarted || _shiftStart == null) {
      return;
    }

    final shiftEnd = DateTime.now();
    final settlement = await ref.read(driverTaskServiceProvider).closeShift(
          driverId: 'driver-001',
          shiftStart: _shiftStart!,
          shiftEnd: shiftEnd,
        );

    _shiftTimer?.cancel();
    setState(() {
      _shiftStarted = false;
      _shiftStart = null;
      _elapsed = Duration.zero;
    });

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Shift summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliveries completed: ${settlement.completedAssignments}'),
              Text('Total due: ${_formatCurrency(settlement.totalDue)}'),
              Text('Cash collected: ${_formatCurrency(settlement.collectedCash)}'),
              Text('Pending remit: ${_formatCurrency(settlement.pendingRemittance)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _advanceTask(DriverTask task) async {
    final nextStatus = _nextStatus(task.status);
    if (nextStatus == null) {
      return;
    }

    if (nextStatus == DriverTaskStatus.delivered && task.requiresCollection) {
      final result = await _promptCollection(task);
      if (result == null) {
        return;
      }
      await ref.read(driverTaskServiceProvider).updateStatus(
            task.id,
            nextStatus,
            collectedAmount: result.amount,
            paymentMethod: result.method,
          );
    } else {
      await ref.read(driverTaskServiceProvider).updateStatus(
            task.id,
            nextStatus,
          );
    }
  }

  Future<void> _reportIssue(DriverTask task) async {
    final controller = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report delivery issue'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe the issue',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (notes != null && notes.isNotEmpty) {
      await ref.read(driverTaskServiceProvider).updateStatus(
            task.id,
            DriverTaskStatus.failed,
            notes: notes,
          );
    }
  }

  Future<_CollectionResult?> _promptCollection(DriverTask task) async {
    final amountController =
        TextEditingController(text: task.amountDue.toStringAsFixed(2));
    DriverPaymentMethod selectedMethod = DriverPaymentMethod.cash;

    return showModalBottomSheet<_CollectionResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm collection',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount collected',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DriverPaymentMethod>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                ),
                items: DriverPaymentMethod.values
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedMethod = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final parsed = double.tryParse(amountController.text);
                  if (parsed == null) {
                    Navigator.of(context).pop();
                    return;
                  }
                  Navigator.of(context).pop(
                    _CollectionResult(parsed, selectedMethod),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirm delivery'),
              ),
            ],
          ),
        );
      },
    );
  }

  DriverTaskStatus? _nextStatus(DriverTaskStatus status) {
    switch (status) {
      case DriverTaskStatus.assigned:
        return DriverTaskStatus.accepted;
      case DriverTaskStatus.accepted:
        return DriverTaskStatus.pickedUp;
      case DriverTaskStatus.pickedUp:
        return DriverTaskStatus.enRoute;
      case DriverTaskStatus.enRoute:
        return DriverTaskStatus.delivered;
      case DriverTaskStatus.delivered:
      case DriverTaskStatus.failed:
      case DriverTaskStatus.cancelled:
        return null;
    }
  }

  String _statusActionLabel(DriverTaskStatus status) {
    switch (status) {
      case DriverTaskStatus.assigned:
        return 'Accept task';
      case DriverTaskStatus.accepted:
        return 'Picked up';
      case DriverTaskStatus.pickedUp:
        return 'Start delivery';
      case DriverTaskStatus.enRoute:
        return 'Complete delivery';
      case DriverTaskStatus.delivered:
        return 'Completed';
      case DriverTaskStatus.failed:
      case DriverTaskStatus.cancelled:
        return 'Closed';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(name: 'SAR');
    return format.format(value);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CollectionResult {
  _CollectionResult(this.amount, this.method);
  final double amount;
  final DriverPaymentMethod method;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTaskTile extends ConsumerWidget {
  const _RecentTaskTile({required this.task});

  final DriverTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.delivery_dining),
        title: Text('Order #${task.orderId} · ${task.customerName}'),
        subtitle: Text(task.dropoffAddress),
        trailing: Chip(label: Text(task.status.name)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderNavigationScreen(task: task),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.details});

  final String message;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              details,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.task});

  final DriverTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(driverRouteHistoryProvider(task.id));
    final liveAsync = ref.watch(driverLiveRouteProvider(task.id));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alt_route, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Route for order #${task.orderId}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            routeAsync.when(
              data: (points) {
                final latest = points.isNotEmpty ? points.last : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recorded points: ${points.length}'),
                    if (latest != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Last fix • ${latest.latitude.toStringAsFixed(5)}, '
                          '${latest.longitude.toStringAsFixed(5)} @ '
                          '${DateFormat.Hms().format(latest.recordedAt)}',
                        ),
                      ),
                  ],
                );
              },
              error: (error, stackTrace) => Text('Unable to load route: $error'),
              loading: () => const Text('Loading route history…'),
            ),
            const SizedBox(height: 12),
            liveAsync.when(
              data: (point) => Text(
                'Live speed: ${point.speedKph.toStringAsFixed(1)} km/h · '
                'Update interval ${point.intervalSeconds ?? 0}s',
              ),
              error: (error, stackTrace) => Text('GPS stream error: $error'),
              loading: () => const Text('Awaiting live telemetry…'),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderNavigationScreen(task: task),
                  ),
                ),
                icon: const Icon(Icons.navigation),
                label: const Text('Open navigation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
