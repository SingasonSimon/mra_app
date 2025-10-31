enum MedEventStatus { taken, snoozed, skipped }

class MedLog {
  final String id;
  final String medicationId;
  final DateTime timestamp;
  final MedEventStatus status;
  final DateTime scheduledDoseTime;
  final String? notes;

  MedLog({
    required this.id,
    required this.medicationId,
    required this.timestamp,
    required this.status,
    required this.scheduledDoseTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicationId': medicationId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'scheduledDoseTime': scheduledDoseTime.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  static MedLog fromMap(String id, Map<String, dynamic> map) {
    return MedLog(
      id: id,
      medicationId: map['medicationId'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: MedEventStatus.values.firstWhere((e) => e.name == map['status'] as String),
      scheduledDoseTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledDoseTime'] as int),
      notes: map['notes'] as String?,
    );
  }
}


