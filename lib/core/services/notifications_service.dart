import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import '../models/med_log.dart';
import '../models/appointment.dart';
import '../models/medication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static Function(String medicationId, MedEventStatus status)? onActionTapped;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final location = tz.getLocation('UTC');
    tz.setLocalLocation(location);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) async {
    // Handle notification action button taps
    final actionId = response.actionId;
    final payload = response.payload;
    
    if (actionId != null && payload != null) {
      // Payload format: medicationId|action
      final parts = payload.split('|');
      if (parts.length >= 2) {
        final medicationId = parts[0];
        
        MedEventStatus? status;
        if (actionId == 'take') {
          status = MedEventStatus.taken;
        } else if (actionId == 'snooze') {
          status = MedEventStatus.snoozed;
        } else if (actionId == 'skip') {
          status = MedEventStatus.skipped;
        }

        if (status != null) {
          await _logMedicationEvent(medicationId, status);
        }
      }
    } else if (payload != null && actionId == null) {
      // Notification body tapped - could navigate to medication detail
      // For now, just log as tapped
    }
  }

  Future<void> _logMedicationEvent(String medicationId, MedEventStatus status) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final log = {
        'medicationId': medicationId,
        'timestamp': now.millisecondsSinceEpoch,
        'status': status.name,
        'scheduledDoseTime': now.millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medLogs')
          .add(log);
    } catch (e) {
      // Silently fail - logging errors shouldn't crash the app
      debugPrint('Error logging medication event: $e');
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? medicationId,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication doses',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction('take', 'Take', showsUserInterface: false),
        AndroidNotificationAction('snooze', 'Snooze', showsUserInterface: false),
        AndroidNotificationAction('skip', 'Skip', showsUserInterface: false),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Include medication ID in payload for action handlers
    // Format: medicationId|action (action will be set by button tap)
    final payload = medicationId != null ? '$medicationId|' : null;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleRecurringReminder({
    required int baseId,
    required String title,
    required String body,
    required TimeOfDay time,
    String? medicationId,
  }) async {
    await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleMedicationReminder(
      id: baseId,
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      medicationId: medicationId,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required int id,
    required Appointment appointment,
  }) async {
    await initialize();

    if (!appointment.reminderEnabled) return;

    // Calculate reminder time (X minutes before appointment)
    final reminderTime = appointment.dateTime.subtract(
      Duration(minutes: appointment.reminderMinutesBefore),
    );

    // Don't schedule if reminder time has already passed
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Appointment reminder time has already passed');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for medical appointments',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Format reminder message
    final timeStr = appointment.formattedTime;
    final reminderMsg = 'Appointment with ${appointment.doctorName} at $timeStr\n'
        'Reason: ${appointment.reason}';

    await _notifications.zonedSchedule(
      id,
      'Upcoming Appointment',
      reminderMsg,
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // Handle recurring appointments - schedule next occurrence
    if (appointment.isRecurring && appointment.recurrencePattern != null) {
      _scheduleRecurringAppointment(appointment, id);
    }
  }

  void _scheduleRecurringAppointment(Appointment appointment, int baseId) {
    // This is a placeholder for recurring appointment logic
    // In a production app, you'd want to schedule the next occurrence
    // based on the recurrence pattern (daily, weekly, monthly)
    // For now, we'll handle this when the user views/edits the appointment
    debugPrint('Recurring appointment detected: ${appointment.recurrencePattern}');
  }

  Future<void> cancelAppointmentReminder(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> scheduleRefillReminder({
    required int id,
    required Medication medication,
  }) async {
    await initialize();

    if (medication.refillDate == null) {
      return; // No refill date set
    }

    // Don't schedule if refill date has already passed
    if (medication.refillDate!.isBefore(DateTime.now())) {
      debugPrint('Refill date has already passed');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'refill_reminders',
      'Refill Reminders',
      channelDescription: 'Notifications for medication refills',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Format reminder message
    final refillDateStr = '${medication.refillDate!.day}/${medication.refillDate!.month}/${medication.refillDate!.year}';
    final reminderMsg = 'Time to refill ${medication.name}\n'
        'Refill date: $refillDateStr\n'
        'Dosage: ${medication.dosage}';

    await _notifications.zonedSchedule(
      id,
      'Medication Refill Reminder',
      reminderMsg,
      tz.TZDateTime.from(medication.refillDate!, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelRefillReminder(int id) async {
    await _notifications.cancel(id);
  }
}

