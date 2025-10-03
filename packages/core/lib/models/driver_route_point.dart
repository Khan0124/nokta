class DriverRoutePoint {
  const DriverRoutePoint({
    required this.id,
    required this.taskId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.speedKph,
    required this.accuracy,
    this.heading,
    this.intervalSeconds,
  });

  final String id;
  final String taskId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double speedKph;
  final double accuracy;
  final double? heading;
  final int? intervalSeconds;

  DriverRoutePoint copyWith({
    double? latitude,
    double? longitude,
    DateTime? recordedAt,
    double? speedKph,
    double? accuracy,
    double? heading,
    int? intervalSeconds,
  }) {
    return DriverRoutePoint(
      id: id,
      taskId: taskId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recordedAt: recordedAt ?? this.recordedAt,
      speedKph: speedKph ?? this.speedKph,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': recordedAt.toIso8601String(),
      'speed_kph': speedKph,
      'accuracy': accuracy,
      'heading': heading,
      'interval_seconds': intervalSeconds,
    };
  }

  factory DriverRoutePoint.fromMap(Map<String, dynamic> map) {
    return DriverRoutePoint(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      speedKph: (map['speed_kph'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      heading: map['heading'] != null ? (map['heading'] as num).toDouble() : null,
      intervalSeconds: map['interval_seconds'] as int?,
    );
  }
}
