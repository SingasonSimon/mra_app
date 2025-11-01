import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/med_log.dart';
import '../models/appointment.dart';
import '../models/medication.dart';
import '../../features/logs/repository/logs_repository.dart';
import '../../features/medication/repository/medication_repository.dart';

class NotificationsService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final LogsRepository _logsRepository = LogsRepository();
  final MedicationRepository _medicationRepository = MedicationRepository();
  static GlobalKey<NavigatorState>? navigatorKey;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    
    // Get device's actual timezone
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final offsetHours = offset.inHours;
    debugPrint('Device timezone offset: $offset hours');
    debugPrint('Local time: $now');
    debugPrint('UTC time: ${now.toUtc()}');
    
    // Try to map common timezone names to IANA locations based on offset
    // This is a workaround - ideally use flutter_timezone package
    String? locationName;
    final tzName = now.timeZoneName;
    debugPrint('System timezone name: $tzName');
    
    // Map common timezone names to IANA locations
    final tzMap = {
      'EAT': 'Africa/Nairobi',      // East Africa Time (UTC+3)
      'CAT': 'Africa/Harare',       // Central Africa Time (UTC+2)
      'WAT': 'Africa/Lagos',        // West Africa Time (UTC+1)
      'GMT': 'Europe/London',       // Greenwich Mean Time (UTC+0)
      'EST': 'America/New_York',    // Eastern Standard Time (UTC-5)
      'PST': 'America/Los_Angeles', // Pacific Standard Time (UTC-8)
    };
    
    if (tzMap.containsKey(tzName)) {
      locationName = tzMap[tzName];
    } else {
      // Try common locations based on offset
      final offsetMap = {
        3: 'Africa/Nairobi',    // EAT
        2: 'Africa/Cairo',    // CAT
        1: 'Africa/Lagos',    // WAT
        0: 'UTC',
        -5: 'America/New_York',
        -8: 'America/Los_Angeles',
      };
      locationName = offsetMap[offsetHours];
    }
    
    try {
      if (locationName != null) {
        tz.setLocalLocation(tz.getLocation(locationName));
        debugPrint('Set timezone location: ${tz.local.name}');
      } else {
        throw Exception('Could not determine timezone location');
      }
    } catch (e) {
      debugPrint('Error setting timezone location: $e');
      // Fallback: Keep UTC but we'll handle conversion manually
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('Fallback to UTC - will use manual offset conversion');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    debugPrint('Notification initialization result: $initialized');

    // Request permissions for Android 13+
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final permissionGranted = await androidImplementation.requestNotificationsPermission();
      debugPrint('Android notification permission granted: $permissionGranted');
    }

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;
    
    debugPrint('Notification tapped - actionId: $actionId, payload: $payload');
    
    if (payload == null || payload.isEmpty) return;
    
    // Payload format: medicationId (no action suffix for body tap)
    final medicationId = payload.split('|')[0];
    
    if (actionId == null) {
      // Notification body tapped - navigate to log medication screen
      final context = navigatorKey?.currentContext;
      if (context != null) {
        GoRouter.of(context).go('/logs/$medicationId');
      }
      return;
    }
    
    // Action button tapped
    MedEventStatus? status;
    if (actionId == 'take') {
      status = MedEventStatus.taken;
    } else if (actionId == 'skip') {
      status = MedEventStatus.skipped;
    } else if (actionId == 'snooze') {
      status = MedEventStatus.snoozed;
    }
    
    if (status == null) return;
    
    try {
      // Get medication to determine scheduled time
      final medication = await _medicationRepository.getMedication(medicationId);
      if (medication == null) {
        debugPrint('Medication not found: $medicationId');
        return;
      }
      
      final now = DateTime.now();
      // Find closest scheduled time for today
      TimeOfDay? scheduledTime;
      final currentTimeOfDay = TimeOfDay.fromDateTime(now);
      
      for (final time in medication.timesPerDay) {
        final timeMinutes = time.hour * 60 + time.minute;
        final currentMinutes = currentTimeOfDay.hour * 60 + currentTimeOfDay.minute;
        
        if (timeMinutes >= currentMinutes - 30 && timeMinutes <= currentMinutes + 30) {
          scheduledTime = time;
          break;
        }
      }
      
      if (scheduledTime == null && medication.timesPerDay.isNotEmpty) {
        // Use the first scheduled time if no match found
        scheduledTime = medication.timesPerDay.first;
      }
      
      final scheduledDateTime = scheduledTime != null
          ? DateTime(now.year, now.month, now.day, scheduledTime.hour, scheduledTime.minute)
          : now;
      
      // Log the medication event
      final log = MedLog(
        id: '',
        medicationId: medicationId,
        timestamp: now,
        status: status,
        scheduledDoseTime: scheduledDateTime,
      );
      
      await _logsRepository.logMedicationEvent(log);
      debugPrint('Logged medication event: $medicationId - ${status.name}');
      
      // If snoozed, reschedule notification for 15 minutes later
      if (status == MedEventStatus.snoozed) {
        final snoozeTime = now.add(const Duration(minutes: 15));
        await scheduleMedicationReminder(
          id: medicationId.hashCode,
          title: 'Medication Reminder',
          body: 'Time to take ${medication.name} (${medication.dosage})',
          scheduledTime: snoozeTime,
          medicationId: medicationId,
          useRecurring: false,
        );
        debugPrint('Rescheduled notification for 15 minutes later');
      }
      
      // Navigate to log screen to show confirmation
      if (navigatorKey?.currentContext != null) {
        navigatorKey!.currentContext!.go('/logs/$medicationId');
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? medicationId,
    bool useRecurring = true,
    bool playSound = true,
  }) async {
    await initialize();

    // Use custom alarm sound for medication reminders if sound is enabled
    // Android: Place alarm.mp3, alarm.wav, or alarm.ogg in android/app/src/main/res/raw/
    // iOS: Place alarm.caf, alarm.aiff, or alarm.wav in ios/Runner/
    // If sound file doesn't exist, Android will use default notification sound
    final androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication doses',
      importance: Importance.max, // Max importance for alarm-like behavior
      priority: Priority.high,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500]), // Vibrate pattern: wait 0ms, vibrate 500ms, pause 250ms, repeat
      playSound: playSound,
      sound: playSound ? const RawResourceAndroidNotificationSound('alarm') : null, // Custom alarm sound (10-15 seconds) or null if sound disabled
      ongoing: false, // Not ongoing - allows dismissal
      autoCancel: false, // Don't auto-cancel so user can interact with it
      actions: const [
        AndroidNotificationAction('take', 'Take', showsUserInterface: false),
        AndroidNotificationAction('snooze', 'Snooze', showsUserInterface: false),
        AndroidNotificationAction('skip', 'Skip', showsUserInterface: false),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
      sound: playSound ? 'alarm.caf' : null, // Custom alarm sound for iOS or null if sound disabled
      categoryIdentifier: 'MEDICATION_REMINDER',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Include medication ID in payload for navigation and action handling
    final payload = medicationId;

    try {
      // scheduledTime is in LOCAL device timezone
      // Android AlarmManager needs UTC time, so convert local -> UTC
      // The flutter_local_notifications package expects TZDateTime.utc for reliable scheduling
      
      final utcTime = scheduledTime.toUtc();
      final tzDateTime = tz.TZDateTime.utc(
        utcTime.year,
        utcTime.month,
        utcTime.day,
        utcTime.hour,
        utcTime.minute,
        utcTime.second,
      );
      
      final now = DateTime.now();
      final timeUntilFire = scheduledTime.difference(now);
      
      debugPrint('Scheduling notification: id=$id');
      debugPrint('  Local scheduled time: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')} (${scheduledTime.timeZoneName})');
      debugPrint('  Converted to UTC: ${utcTime.hour}:${utcTime.minute.toString().padLeft(2, '0')} UTC');
      debugPrint('  TZDateTime: $tzDateTime');
      debugPrint('  Time until fire: ${timeUntilFire.inMinutes} minutes ${timeUntilFire.inSeconds % 60} seconds');
      debugPrint('  Notification will appear at device local time: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}');
      debugPrint('  Title: $title');
      debugPrint('  Body: $body');
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        details,
        payload: payload,
        // exactAllowWhileIdle ensures notifications fire even when:
        // - App is closed/terminated
        // - Device is in doze mode
        // - Device screen is off
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: useRecurring ? DateTimeComponents.time : null,
      );
      debugPrint('Notification scheduled successfully with id=$id (recurring: $useRecurring)');
      debugPrint('  Will fire at device local time: ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}');
    } on Exception catch (e) {
      debugPrint('Error scheduling notification: $e');
      // If exact alarms are not permitted, try with inexact scheduling
      if (e.toString().contains('exact_alarms_not_permitted')) {
        debugPrint('Exact alarms not permitted, using inexact scheduling');
        try {
          final utcTimeFallback = scheduledTime.toUtc();
          final tzDateTimeFallback = tz.TZDateTime.utc(
            utcTimeFallback.year,
            utcTimeFallback.month,
            utcTimeFallback.day,
            utcTimeFallback.hour,
            utcTimeFallback.minute,
            utcTimeFallback.second,
          );
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            tzDateTimeFallback,
            details,
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: useRecurring ? DateTimeComponents.time : null,
          );
        } catch (e2) {
          debugPrint('Failed to schedule notification (inexact): $e2');
          // Silently fail - notification scheduling shouldn't block medication saving
        }
      } else {
        debugPrint('Failed to schedule notification: $e');
        // Silently fail - notification scheduling shouldn't block medication saving
      }
    }
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
    bool playSound = true,
  }) async {
    await initialize();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    debugPrint('Scheduling reminder: TimeOfDay=${time.hour}:${time.minute.toString().padLeft(2, '0')}, Now=${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    debugPrint('Initial scheduledDate: $scheduledDate');

    // Ensure notification is scheduled at least 5 seconds in the future
    // Android requires some buffer time to schedule notifications
    final minScheduleTime = now.add(const Duration(seconds: 5));
    
    if (scheduledDate.isBefore(minScheduleTime)) {
      // If time is too close or has passed, schedule for tomorrow
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('Time too close or passed, scheduling for tomorrow: $scheduledDate');
    } else {
      debugPrint('Scheduling for today: $scheduledDate');
      final timeDiff = scheduledDate.difference(now);
      debugPrint('Time difference: ${timeDiff.inMinutes} minutes ${timeDiff.inSeconds % 60} seconds');
    }

    // Schedule the notification - don't use matchDateTimeComponents for the first one
    // This ensures it fires at the exact time specified
    await scheduleMedicationReminder(
      id: baseId,
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      medicationId: medicationId,
      useRecurring: false, // First notification is exact
      playSound: playSound,
    );
    
    // Schedule recurring notification starting from tomorrow
    final tomorrowDate = scheduledDate.add(const Duration(days: 1));
    await scheduleMedicationReminder(
      id: baseId + 100000, // Different ID for recurring
      title: title,
      body: body,
      scheduledTime: tomorrowDate,
      medicationId: medicationId,
      useRecurring: true, // Recurring from tomorrow
      playSound: playSound,
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

    try {
      await _notifications.zonedSchedule(
        id,
        'Upcoming Appointment',
        reminderMsg,
        tz.TZDateTime.from(reminderTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted')) {
        debugPrint('Exact alarms not permitted, using inexact scheduling for appointment');
        try {
          await _notifications.zonedSchedule(
            id,
            'Upcoming Appointment',
            reminderMsg,
            tz.TZDateTime.from(reminderTime, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e2) {
          debugPrint('Failed to schedule appointment reminder: $e2');
        }
      } else {
        debugPrint('Failed to schedule appointment reminder: $e');
      }
    }

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

    try {
      await _notifications.zonedSchedule(
        id,
        'Medication Refill Reminder',
        reminderMsg,
        tz.TZDateTime.from(medication.refillDate!, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted')) {
        debugPrint('Exact alarms not permitted, using inexact scheduling for refill');
        try {
          await _notifications.zonedSchedule(
            id,
            'Medication Refill Reminder',
            reminderMsg,
            tz.TZDateTime.from(medication.refillDate!, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e2) {
          debugPrint('Failed to schedule refill reminder: $e2');
        }
      } else {
        debugPrint('Failed to schedule refill reminder: $e');
      }
    }
  }

  Future<void> cancelRefillReminder(int id) async {
    await _notifications.cancel(id);
  }
}

