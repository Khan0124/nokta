// apps/driver_app/lib/screens/navigation/order_navigation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

// Placeholder directions service
class DirectionsService {
  Future<DirectionsResult> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Placeholder implementation - in real app, would call Google Directions API
    return DirectionsResult(
      polylinePoints: [origin, destination],
    );
  }
}

class DirectionsResult {
  final List<LatLng> polylinePoints;
  
  DirectionsResult({required this.polylinePoints});
}

// Provider
final directionsServiceProvider = Provider<DirectionsService>((ref) => DirectionsService());

// Placeholder for DeliveryOrder model
class DeliveryOrder {
  final int id;
  final String customerName;
  final String customerAddress;
  final LatLng currentDestination;
  final String currentDestinationTitle;
  final String currentDestinationAddress;
  final bool isPickup;
  final double remainingDistance;
  final int estimatedTime;
  
  DeliveryOrder({
    required this.id,
    required this.customerName,
    required this.customerAddress,
    required this.currentDestination,
    required this.currentDestinationTitle,
    required this.currentDestinationAddress,
    required this.isPickup,
    required this.remainingDistance,
    required this.estimatedTime,
  });
}

class OrderNavigationScreen extends ConsumerStatefulWidget {
  final DeliveryOrder order;
  
  const OrderNavigationScreen({super.key, required this.order});
  
  @override
  ConsumerState<OrderNavigationScreen> createState() => _OrderNavigationScreenState();
}

class _OrderNavigationScreenState extends ConsumerState<OrderNavigationScreen> {
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  late LatLng _currentLocation;
  
  @override
  void initState() {
    super.initState();
    _currentLocation = const LatLng(24.7136, 46.6753); // Default to Riyadh
    _getCurrentLocation();
    _setupRoute();
  }
  
  Future<void> _getCurrentLocation() async {
    // Implementation for getting current location
    // This would typically use location services
  }
  
  void _fitMapToRoute() {
    // Implementation for fitting map to show route
  }
  
  void _handleArrival() {
    // Implementation for handling arrival
  }
  
  Future<void> _setupRoute() async {
    // Get route from current location to destination
    final directions = await ref.read(directionsServiceProvider).getDirections(
      origin: _currentLocation,
      destination: widget.order.currentDestination,
    );
    
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: directions.polylinePoints,
          color: Theme.of(context).primaryColor,
          width: 5,
        ),
      };
      
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.order.currentDestination,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: widget.order.currentDestinationTitle,
            snippet: widget.order.currentDestinationAddress,
          ),
        ),
      };
    });
    
    // Fit map to show route
    _fitMapToRoute();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          
          // Navigation Info Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.order.isPickup
                              ? Icons.restaurant
                              : Icons.home,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.currentDestinationTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                widget.order.currentDestinationAddress,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Distance'),
                            Text(
                              '${widget.order.remainingDistance} km',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Time'),
                            Text(
                              '${widget.order.estimatedTime} min',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _handleArrival,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                widget.order.isPickup
                    ? 'Arrived at Restaurant'
                    : 'Arrived at Customer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}