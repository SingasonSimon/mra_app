import 'package:flutter/material.dart';

class Appointment {
  final String id;
  final String doctorName;
  final DateTime dateTime;
  final String reason;
  final String? location;
  final String? phone;
  final String? notes;
  final bool reminderEnabled;
  final int reminderMinutesBefore; // e.g., 15, 30, 60, 120, 1440 (24 hours)
  final bool isRecurring;
  final String? recurrencePattern; // e.g., "daily", "weekly", "monthly", "custom"
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.dateTime,
    required this.reason,
    this.location,
    this.phone,
    this.notes,
    this.reminderEnabled = true,
    this.reminderMinutesBefore = 30,
    this.isRecurring = false,
    this.recurrencePattern,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'reason': reason,
      'location': location,
      'phone': phone,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static Appointment fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      doctorName: map['doctorName'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime'] as int),
      reason: map['reason'] as String,
      location: map['location'] as String?,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      reminderEnabled: map['reminderEnabled'] as bool? ?? true,
      reminderMinutesBefore: map['reminderMinutesBefore'] as int? ?? 30,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurrencePattern: map['recurrencePattern'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Appointment copyWith({
    String? id,
    String? doctorName,
    DateTime? dateTime,
    String? reason,
    String? location,
    String? phone,
    String? notes,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      reason: reason ?? this.reason,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool get isPast => dateTime.isBefore(DateTime.now());
  
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (appointmentDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String get formattedTime {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}

