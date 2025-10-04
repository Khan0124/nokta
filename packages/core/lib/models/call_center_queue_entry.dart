import 'package:equatable/equatable.dart';

class CallCenterQueueEntry extends Equatable {
  const CallCenterQueueEntry({
    required this.id,
    required this.callerNumber,
    required this.displayName,
    required this.status,
    required this.waitingSince,
    required this.priority,
    this.customerId,
    this.lastOrderId,
    this.notes,
    this.agentId,
    this.preferredBranchId,
    this.loyaltyPoints = 0,
    this.lastOrderAt,
  });

  factory CallCenterQueueEntry.fromJson(Map<String, dynamic> json) {
    final statusString = (json['status'] as String? ?? 'queued').toLowerCase();
    final status = _statusFromString(statusString);

    return CallCenterQueueEntry(
      id: json['id']?.toString() ?? json['callerNumber']?.toString() ?? '',
      callerNumber: json['callerNumber']?.toString() ?? json['phone']?.toString() ?? 'unknown',
      displayName: json['displayName']?.toString() ?? json['callerNumber']?.toString() ?? 'Unknown Caller',
      status: status,
      waitingSince: DateTime.tryParse(json['waitingSince']?.toString() ?? '') ?? DateTime.now(),
      priority: json['priority'] is num ? (json['priority'] as num).round() : 50,
      customerId: json['customerId'] as int?,
      lastOrderId: json['lastOrderId'] as int?,
      notes: json['notes']?.toString(),
      agentId: json['agentId'] as int?,
      preferredBranchId: json['preferredBranchId'] as int?,
      loyaltyPoints: json['loyaltyPoints'] is num ? (json['loyaltyPoints'] as num).round() : 0,
      lastOrderAt: json['lastOrderAt'] != null
          ? DateTime.tryParse(json['lastOrderAt'].toString())
          : null,
    );
  }

  final String id;
  final String callerNumber;
  final String displayName;
  final CallCenterQueueStatus status;
  final DateTime waitingSince;
  final int priority;
  final int? customerId;
  final int? lastOrderId;
  final String? notes;
  final int? agentId;
  final int? preferredBranchId;
  final int loyaltyPoints;
  final DateTime? lastOrderAt;

  Duration get waitingDuration => DateTime.now().difference(waitingSince);

  CallCenterQueueEntry copyWith({
    CallCenterQueueStatus? status,
    DateTime? waitingSince,
    int? priority,
    String? displayName,
  }) {
    return CallCenterQueueEntry(
      id: id,
      callerNumber: callerNumber,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      waitingSince: waitingSince ?? this.waitingSince,
      priority: priority ?? this.priority,
      customerId: customerId,
      lastOrderId: lastOrderId,
      notes: notes,
      agentId: agentId,
      preferredBranchId: preferredBranchId,
      loyaltyPoints: loyaltyPoints,
      lastOrderAt: lastOrderAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerNumber': callerNumber,
      'displayName': displayName,
      'status': status.name,
      'waitingSince': waitingSince.toIso8601String(),
      'priority': priority,
      'customerId': customerId,
      'lastOrderId': lastOrderId,
      'notes': notes,
      'agentId': agentId,
      'preferredBranchId': preferredBranchId,
      'loyaltyPoints': loyaltyPoints,
      'lastOrderAt': lastOrderAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        callerNumber,
        displayName,
        status,
        waitingSince,
        priority,
        customerId,
        lastOrderId,
        notes,
        agentId,
        preferredBranchId,
        loyaltyPoints,
        lastOrderAt,
      ];
}

enum CallCenterQueueStatus {
  waiting,
  assigned,
  resolved,
}

CallCenterQueueStatus _statusFromString(String value) {
  switch (value) {
    case 'queued':
    case 'waiting':
      return CallCenterQueueStatus.waiting;
    case 'active':
    case 'assigned':
      return CallCenterQueueStatus.assigned;
    case 'completed':
    case 'resolved':
      return CallCenterQueueStatus.resolved;
    default:
      return CallCenterQueueStatus.waiting;
  }
}
