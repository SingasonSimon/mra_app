import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../medication/providers/medication_providers.dart';
import '../../logs/providers/logs_providers.dart';
import '../../logs/repository/logs_repository.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/med_log.dart';
import 'package:intl/intl.dart';

/// Helper function to get today's medications
Future<List<TodayMedication>> _getTodaysMedications(
  List<Medication> medications,
  LogsRepository logsRepo,
) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  final todayMeds = <TodayMedication>[];
  
  for (final med in medications) {
    // Skip if medication hasn't started or has ended
    if (med.startDate.isAfter(endOfDay)) continue;
    if (med.endDate != null && med.endDate!.isBefore(startOfDay)) continue;
    
    // Get all scheduled times for today
    for (final time in med.timesPerDay) {
      final scheduledTime = DateTime(
        today.year,
        today.month,
        today.day,
        time.hour,
        time.minute,
      );
      
      // Get logs for this medication - only for TODAY
      try {
        final logs = await logsRepo.getLogsForMedication(med.id);
        // Filter logs to only include those scheduled for TODAY with the exact time
        final todayLogs = logs.where((log) {
          final logDate = log.scheduledDoseTime;
          final isSameDay = logDate.year == today.year && 
                          logDate.month == today.month && 
                          logDate.day == today.day;
          final isSameTime = logDate.hour == time.hour && 
                           logDate.minute == time.minute;
          return isSameDay && isSameTime;
        }).toList();
        
        // For a new day, if no logs exist, status should be null/not taken
        // This allows the "Mark Taken" button to show
        final status = todayLogs.isNotEmpty 
            ? todayLogs.first.status 
            : null; // null means not logged yet - will show "Mark Taken"
        
        todayMeds.add(TodayMedication(
          medication: med,
          scheduledTime: scheduledTime,
          status: status,
          logId: todayLogs.isNotEmpty ? todayLogs.first.id : null,
        ));
      } catch (e) {
        // If error, assume not taken (null status shows "Mark Taken" button)
        todayMeds.add(TodayMedication(
          medication: med,
          scheduledTime: scheduledTime,
          status: null,
          logId: null,
        ));
      }
    }
  }
  
  // Sort by scheduled time
  todayMeds.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  
  return todayMeds;
}

/// Provider for today's medications with their dose times and status
/// This provider refreshes when medications change AND periodically checks for day changes
final todayMedicationsProvider = StreamProvider<List<TodayMedication>>((ref) async* {
  final medicationsRepository = ref.watch(medicationRepositoryProvider);
  final logsRepo = ref.watch(logsRepositoryProvider);
  
  // Track the current day to detect day changes
  DateTime? lastDay;
  
  // Periodic timer to check for day changes (every minute)
  Timer? dayCheckTimer;
  dayCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    
    if (lastDay != null && !lastDay!.isAtSameMomentAs(currentDay)) {
      // Day changed - trigger refresh by invalidating the provider
      // This will cause the stream to restart and fetch fresh data
      ref.invalidateSelf();
    }
    lastDay = currentDay;
  });
  
  // Cleanup timer when provider is disposed
  ref.onDispose(() {
    dayCheckTimer?.cancel();
  });
  
  // Watch medications stream - this will automatically refresh when medications change
  // The timer above will invalidate this provider when day changes
  await for (final medications in medicationsRepository.watchMedications()) {
    final todayMeds = await _getTodaysMedications(medications, logsRepo);
    
    // Initialize lastDay on first run
    if (lastDay == null) {
      final today = DateTime.now();
      lastDay = DateTime(today.year, today.month, today.day);
    }
    
    yield todayMeds;
  }
});

/// Provider for today's adherence percentage
final todayAdherenceProvider = Provider<AsyncValue<TodayAdherence>>((ref) {
  final todayMedsAsync = ref.watch(todayMedicationsProvider);
  
  return todayMedsAsync.when(
    data: (todayMeds) {
      final totalDoses = todayMeds.length;
      final takenDoses = todayMeds.where((m) => m.status == MedEventStatus.taken).length;
      final percentage = totalDoses > 0 ? (takenDoses / totalDoses * 100).round() : 0;
      
      return AsyncValue.data(TodayAdherence(
        total: totalDoses,
        taken: takenDoses,
        percentage: percentage,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for next dose information
final nextDoseProvider = Provider<AsyncValue<NextDose?>>((ref) {
  final todayMedsAsync = ref.watch(todayMedicationsProvider);
  
  return todayMedsAsync.when(
    data: (todayMeds) {
      final now = DateTime.now();
      
      final upcoming = todayMeds.where((med) {
        return med.scheduledTime.isAfter(now) && med.status != MedEventStatus.taken;
      }).toList();
      
      if (upcoming.isEmpty) {
        return const AsyncValue.data(null);
      }
      
      final next = upcoming.first;
      final minutesRemaining = next.scheduledTime.difference(now).inMinutes;
      
      return AsyncValue.data(NextDose(
        medication: next.medication,
        scheduledTime: next.scheduledTime,
        minutesRemaining: minutesRemaining,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Model for today's medication with status
class TodayMedication {
  final Medication medication;
  final DateTime scheduledTime;
  final MedEventStatus? status; // null means not logged yet for today
  final String? logId;

  TodayMedication({
    required this.medication,
    required this.scheduledTime,
    this.status, // Can be null if not logged yet
    this.logId,
  });
}

/// Model for today's adherence stats
class TodayAdherence {
  final int total;
  final int taken;
  final int percentage;

  TodayAdherence({
    required this.total,
    required this.taken,
    required this.percentage,
  });
}

/// Model for next dose info
class NextDose {
  final Medication medication;
  final DateTime scheduledTime;
  final int minutesRemaining;

  NextDose({
    required this.medication,
    required this.scheduledTime,
    required this.minutesRemaining,
  });
  
  String get formattedTime => DateFormat('h:mm a').format(scheduledTime);
}

/// Provider for 7-day adherence percentage
final sevenDayAdherenceProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final logsAsync = ref.watch(logsStreamProvider(DateTime.now()));
  final medicationsAsync = ref.watch(medicationsStreamProvider);
  
  return logsAsync.when(
    data: (logs) {
      return medicationsAsync.when(
        data: (medications) {
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          
          // Get active medications
          final activeMeds = medications.where((med) {
            if (med.startDate.isAfter(now)) return false;
            if (med.endDate != null && med.endDate!.isBefore(now)) return false;
            return true;
          }).toList();
          
          // Calculate expected doses for the week
          int expectedDoses = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = weekAgo.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));
              
              if (med.startDate.isBefore(dayEnd) && (med.endDate == null || med.endDate!.isAfter(dayStart))) {
                expectedDoses += med.timesPerDay.length;
              }
            }
          }
          
          // Count taken doses with proper matching
          int takenDoses = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = weekAgo.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));
              
              if (med.startDate.isBefore(dayEnd) && (med.endDate == null || med.endDate!.isAfter(dayStart))) {
                for (final scheduledTime in med.timesPerDay) {
                  final scheduledDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    scheduledTime.hour,
                    scheduledTime.minute,
                  );
                  
                  final hasLog = logs.any((log) =>
                      log.medicationId == med.id &&
                      log.status == MedEventStatus.taken &&
                      log.timestamp.isAfter(dayStart) &&
                      log.timestamp.isBefore(dayEnd) &&
                      log.scheduledDoseTime.year == scheduledDateTime.year &&
                      log.scheduledDoseTime.month == scheduledDateTime.month &&
                      log.scheduledDoseTime.day == scheduledDateTime.day &&
                      log.scheduledDoseTime.hour == scheduledDateTime.hour &&
                      log.scheduledDoseTime.minute == scheduledDateTime.minute);
                  
                  if (hasLog) {
                    takenDoses++;
                  }
                }
              }
            }
          }
          
          // Fallback
          if (takenDoses == 0 && logs.isNotEmpty) {
            takenDoses = logs.where((log) => 
              log.timestamp.isAfter(weekAgo) && 
              log.status == MedEventStatus.taken
            ).length;
          }
          
          final percentage = expectedDoses > 0 ? (takenDoses / expectedDoses * 100).round() : 0;
          
          return AsyncValue.data({'percentage': percentage, 'taken': takenDoses, 'expected': expectedDoses});
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for current streak
final currentStreakProvider = Provider<AsyncValue<int>>((ref) {
  final logsAsync = ref.watch(logsStreamProvider(DateTime.now()));
  
  return logsAsync.when(
    data: (logs) {
      int streak = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      for (int i = 0; i < 365; i++) {
        final date = today.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final dayLogs = logs.where((log) => 
          log.timestamp.isAfter(dayStart) &&
          log.timestamp.isBefore(dayEnd) &&
          log.status == MedEventStatus.taken
        ).toList();
        
        if (dayLogs.isEmpty) {
          break;
        } else {
          streak++;
        }
      }
      
      return AsyncValue.data(streak);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});
