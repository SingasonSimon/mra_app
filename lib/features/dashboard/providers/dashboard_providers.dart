import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../medication/providers/medication_providers.dart';
import '../../logs/providers/logs_providers.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/med_log.dart';
import 'package:intl/intl.dart';

/// Provider for today's medications with their dose times and status
final todayMedicationsProvider = StreamProvider<List<TodayMedication>>((ref) async* {
  final medicationsRepository = ref.watch(medicationRepositoryProvider);
  final logsRepo = ref.watch(logsRepositoryProvider);
  
  // Watch medications stream directly from repository
  await for (final medications in medicationsRepository.watchMedications()) {
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
        
        // Get logs for this medication
        try {
          final logs = await logsRepo.getLogsForMedication(med.id);
          final todayLogs = logs.where((log) => 
            log.scheduledDoseTime.year == today.year &&
            log.scheduledDoseTime.month == today.month &&
            log.scheduledDoseTime.day == today.day &&
            log.scheduledDoseTime.hour == time.hour &&
            log.scheduledDoseTime.minute == time.minute,
          ).toList();
          
          final status = todayLogs.isNotEmpty 
              ? todayLogs.first.status 
              : MedEventStatus.skipped;
          
          todayMeds.add(TodayMedication(
            medication: med,
            scheduledTime: scheduledTime,
            status: status,
            logId: todayLogs.isNotEmpty ? todayLogs.first.id : null,
          ));
        } catch (e) {
          // If error, assume not taken
          todayMeds.add(TodayMedication(
            medication: med,
            scheduledTime: scheduledTime,
            status: MedEventStatus.skipped,
            logId: null,
          ));
        }
      }
    }
    
    // Sort by scheduled time
    todayMeds.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    
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
  final MedEventStatus status;
  final String? logId;

  TodayMedication({
    required this.medication,
    required this.scheduledTime,
    required this.status,
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
