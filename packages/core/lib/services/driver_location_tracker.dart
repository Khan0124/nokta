import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/driver_route_point.dart';

class DriverLocationTracker {
  DriverLocationTracker({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;
  final _uuid = const Uuid();

  Future<void> ensurePermissions() async {
    final serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException('Location services are disabled');
    }

    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('Location permission denied');
    }
  }

  Stream<DriverRoutePoint> trackTask(String taskId) {
    final controller = StreamController<DriverRoutePoint>.broadcast();
    StreamSubscription<Position>? subscription;
    Duration currentInterval = const Duration(seconds: 30);

    LocationSettings _settingsForInterval(Duration interval) {
      final accuracy = interval <= const Duration(seconds: 8)
          ? LocationAccuracy.best
          : LocationAccuracy.high;
      return LocationSettings(
        accuracy: accuracy,
        distanceFilter: interval <= const Duration(seconds: 8) ? 5 : 20,
        intervalDuration: interval,
      );
    }

    Duration _intervalForSpeed(double speedKph) {
      if (speedKph < 5) {
        return const Duration(seconds: 45);
      }
      if (speedKph < 20) {
        return const Duration(seconds: 20);
      }
      if (speedKph < 50) {
        return const Duration(seconds: 10);
      }
      return const Duration(seconds: 5);
    }

    Future<void> _start(LocationSettings settings) async {
      await subscription?.cancel();
      subscription = _geolocator
          .getPositionStream(locationSettings: settings)
          .listen((position) {
        final speedKph = max(0, (position.speed ?? 0) * 3.6);
        final nextInterval = _intervalForSpeed(speedKph);
        if (nextInterval != currentInterval) {
          currentInterval = nextInterval;
          unawaited(_start(_settingsForInterval(nextInterval)));
        }
        final point = DriverRoutePoint(
          id: _uuid.v4(),
          taskId: taskId,
          latitude: position.latitude,
          longitude: position.longitude,
          recordedAt: position.timestamp ?? DateTime.now(),
          speedKph: speedKph,
          accuracy: position.accuracy ?? 0,
          heading: position.heading,
          intervalSeconds: currentInterval.inSeconds,
        );
        controller.add(point);
      }, onError: controller.addError);
    }

    final initialSettings = _settingsForInterval(currentInterval);
    unawaited(_start(initialSettings));

    controller.onCancel = () async {
      await subscription?.cancel();
      await controller.close();
    };

    return controller.stream;
  }
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException(this.message);
  final String message;

  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

class PermissionDeniedException implements Exception {
  const PermissionDeniedException(this.message);
  final String message;

  @override
  String toString() => 'PermissionDeniedException: $message';
}
