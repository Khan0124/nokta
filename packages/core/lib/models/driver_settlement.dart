class DriverSettlement {
  const DriverSettlement({
    required this.id,
    required this.driverId,
    required this.shiftStart,
    required this.shiftEnd,
    required this.totalAssignments,
    required this.completedAssignments,
    required this.totalDue,
    required this.collectedCash,
    required this.collectedNonCash,
    required this.pendingRemittance,
    required this.generatedAt,
    this.notes,
  });

  final String id;
  final String driverId;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final int totalAssignments;
  final int completedAssignments;
  final double totalDue;
  final double collectedCash;
  final double collectedNonCash;
  final double pendingRemittance;
  final DateTime generatedAt;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'shift_start': shiftStart.toIso8601String(),
      'shift_end': shiftEnd.toIso8601String(),
      'total_assignments': totalAssignments,
      'completed_assignments': completedAssignments,
      'total_due': totalDue,
      'collected_cash': collectedCash,
      'collected_non_cash': collectedNonCash,
      'pending_remittance': pendingRemittance,
      'generated_at': generatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory DriverSettlement.fromMap(Map<String, dynamic> map) {
    return DriverSettlement(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      shiftStart: DateTime.parse(map['shift_start'] as String),
      shiftEnd: DateTime.parse(map['shift_end'] as String),
      totalAssignments: map['total_assignments'] as int,
      completedAssignments: map['completed_assignments'] as int,
      totalDue: (map['total_due'] as num).toDouble(),
      collectedCash: (map['collected_cash'] as num).toDouble(),
      collectedNonCash: (map['collected_non_cash'] as num).toDouble(),
      pendingRemittance: (map['pending_remittance'] as num).toDouble(),
      generatedAt: DateTime.parse(map['generated_at'] as String),
      notes: map['notes'] as String?,
    );
  }
}
