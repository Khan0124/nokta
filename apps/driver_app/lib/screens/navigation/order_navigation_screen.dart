import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nokta_core/nokta_core.dart';

class OrderNavigationScreen extends ConsumerStatefulWidget {
  const OrderNavigationScreen({super.key, required this.task});

  final DriverTask task;

  @override
  ConsumerState<OrderNavigationScreen> createState() => _OrderNavigationScreenState();
}

class _OrderNavigationScreenState
    extends ConsumerState<OrderNavigationScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<List<DriverRoutePoint>>>(
      driverRouteHistoryProvider(widget.task.id),
      (previous, next) {
        next.whenData((points) {
          if (points.isNotEmpty) {
            final last = points.last;
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(last.latitude, last.longitude),
              ),
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(driverRouteHistoryProvider(widget.task.id));
    final liveAsync = ref.watch(driverLiveRouteProvider(widget.task.id));
    final currentTask = ref.watch(driverTaskHistoryProvider).maybeWhen(
          data: (tasks) {
            try {
              return tasks.firstWhere((task) => task.id == widget.task.id);
            } catch (_) {
              return widget.task;
            }
          },
          orElse: () => widget.task,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${currentTask.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final points = routeAsync.asData?.value;
              if (points != null && points.isNotEmpty) {
                final last = points.last;
                await _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(last.latitude, last.longitude),
                    16,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: routeAsync.when(
        data: (points) {
          final dropoff = LatLng(currentTask.latitude, currentTask.longitude);
          final polylinePoints = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          final polylines = <Polyline>{
            if (polylinePoints.length >= 2)
              Polyline(
                polylineId: const PolylineId('delivery_route'),
                color: Theme.of(context).colorScheme.primary,
                width: 5,
                points: polylinePoints,
              ),
          };
          final markers = <Marker>{
            Marker(
              markerId: const MarkerId('dropoff'),
              position: dropoff,
              infoWindow: InfoWindow(
                title: currentTask.customerName,
                snippet: currentTask.dropoffAddress,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          };
          if (polylinePoints.isNotEmpty) {
            markers.add(
              Marker(
                markerId: const MarkerId('current'),
                position: polylinePoints.last,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: polylinePoints.isNotEmpty
                        ? polylinePoints.last
                        : dropoff,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  polylines: polylines,
                  markers: markers,
                ),
              ),
              _buildInfoPanel(currentTask, liveAsync),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load navigation data: $error'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildInfoPanel(
    DriverTask task,
    AsyncValue<DriverRoutePoint> liveAsync,
  ) {
    final statuses = [
      DriverTaskStatus.assigned,
      DriverTaskStatus.accepted,
      DriverTaskStatus.pickedUp,
      DriverTaskStatus.enRoute,
      DriverTaskStatus.delivered,
    ];
    final currentIndex = statuses.indexOf(task.status).clamp(0, statuses.length - 1);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.customerName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(task.dropoffAddress),
                        const SizedBox(height: 4),
                        Text('Contact: ${task.customerPhone}'),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(task.status.name.toUpperCase()),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
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
              ),
              const SizedBox(height: 12),
              liveAsync.when(
                data: (point) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Speed ${point.speedKph.toStringAsFixed(1)} km/h',
                    ),
                    Text('Update ${point.intervalSeconds ?? 0}s'),
                  ],
                ),
                error: (error, stackTrace) => Text('GPS error: $error'),
                loading: () => const Text('Awaiting GPS signal…'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _advanceTask(task),
                      icon: const Icon(Icons.flag),
                      label: Text(_statusActionLabel(task.status)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _advanceTask(DriverTask task) async {
    final nextStatus = _nextStatus(task.status);
    if (nextStatus == null) {
      return;
    }

    if (nextStatus == DriverTaskStatus.delivered && task.requiresCollection) {
      final result = await _promptCollection(task);
      if (result == null) return;
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

  Future<_DeliveryCollection?> _promptCollection(DriverTask task) async {
    final controller =
        TextEditingController(text: task.amountDue.toStringAsFixed(2));
    DriverPaymentMethod method = DriverPaymentMethod.cash;

    return showModalBottomSheet<_DeliveryCollection>(
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
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount collected',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DriverPaymentMethod>(
                value: method,
                items: DriverPaymentMethod.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    method = value;
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final parsed = double.tryParse(controller.text);
                  if (parsed == null) {
                    Navigator.of(context).pop();
                    return;
                  }
                  Navigator.of(context).pop(_DeliveryCollection(parsed, method));
                },
                child: const Text('Confirm delivery'),
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
        return 'Delivery complete';
      case DriverTaskStatus.failed:
      case DriverTaskStatus.cancelled:
        return 'Closed';
    }
  }
}

class _DeliveryCollection {
  _DeliveryCollection(this.amount, this.method);
  final double amount;
  final DriverPaymentMethod method;
}
