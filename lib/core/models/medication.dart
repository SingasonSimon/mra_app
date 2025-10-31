import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<TimeOfDay> timesPerDay;
  final String frequency; // e.g., daily, custom
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final int? refillThreshold;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timesPerDay,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.notes,
    this.refillThreshold,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'timesPerDay': timesPerDay.map((t) => '${t.hour}:${t.minute}').toList(),
      'frequency': frequency,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'notes': notes,
      'refillThreshold': refillThreshold,
    };
  }

  static Medication fromMap(String id, Map<String, dynamic> map) {
    List<TimeOfDay> parseTimes(List<dynamic> list) {
      return list
          .map((e) {
            final parts = (e as String).split(':');
            return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          })
          .toList();
    }

    return Medication(
      id: id,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      timesPerDay: parseTimes(map['timesPerDay'] as List<dynamic>),
      frequency: map['frequency'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int) : null,
      notes: map['notes'] as String?,
      refillThreshold: map['refillThreshold'] as int?,
    );
  }
}


