import 'package:equatable/equatable.dart';

class CallCenterMetrics extends Equatable {
  const CallCenterMetrics({
    required this.waitingCalls,
    required this.activeCalls,
    required this.averageWaitSeconds,
    required this.slaBreaches,
    required this.updatedAt,
  });

  factory CallCenterMetrics.fromJson(Map<String, dynamic> json) {
    return CallCenterMetrics(
      waitingCalls: json['queueLength'] is num
          ? (json['queueLength'] as num).round()
          : (json['waitingCalls'] as num?)?.round() ?? 0,
      activeCalls: json['activeCalls'] is num
          ? (json['activeCalls'] as num).round()
          : 0,
      averageWaitSeconds: json['averageWaitTimeSeconds'] is num
          ? (json['averageWaitTimeSeconds'] as num).round()
          : (json['averageWaitSeconds'] as num?)?.round() ?? 0,
      slaBreaches: json['slaBreaches'] is num
          ? (json['slaBreaches'] as num).round()
          : 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final int waitingCalls;
  final int activeCalls;
  final int averageWaitSeconds;
  final int slaBreaches;
  final DateTime updatedAt;

  CallCenterMetrics copyWith({
    int? waitingCalls,
    int? activeCalls,
    int? averageWaitSeconds,
    int? slaBreaches,
    DateTime? updatedAt,
  }) {
    return CallCenterMetrics(
      waitingCalls: waitingCalls ?? this.waitingCalls,
      activeCalls: activeCalls ?? this.activeCalls,
      averageWaitSeconds: averageWaitSeconds ?? this.averageWaitSeconds,
      slaBreaches: slaBreaches ?? this.slaBreaches,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        waitingCalls,
        activeCalls,
        averageWaitSeconds,
      slaBreaches,
      updatedAt,
    ];
}
