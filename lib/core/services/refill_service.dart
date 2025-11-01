import '../models/medication.dart';
import '../models/med_log.dart';
import '../../features/logs/repository/logs_repository.dart';

class RefillService {
  final LogsRepository _logsRepository;

  RefillService(this._logsRepository);

  /// Calculate remaining doses for a medication based on logs
  Future<int> getDosesRemaining(Medication medication) async {
    if (medication.refillThreshold == null) {
      return 0; // No threshold set, can't calculate
    }

    // Get all logs for this medication
    final logs = await _logsRepository.getLogsForMedication(medication.id);

    // Filter logs to only include those after start date and only "taken" doses
    final dosesTaken = logs
        .where((log) => 
            log.status == MedEventStatus.taken && 
            log.timestamp.isAfter(medication.startDate) || 
            log.timestamp.isAtSameMomentAs(medication.startDate))
        .length;

    // Calculate remaining: threshold - doses taken
    final remaining = (medication.refillThreshold! - dosesTaken);
    return remaining > 0 ? remaining : 0;
  }

  /// Calculate refill date automatically based on:
  /// - refillThreshold (total doses)
  /// - timesPerDay (doses per day)
  /// - doses already taken
  Future<DateTime?> calculateRefillDate(Medication medication) async {
    if (medication.refillThreshold == null) {
      return null; // No threshold set, can't calculate
    }

    final dosesPerDay = medication.timesPerDay.length;
    if (dosesPerDay == 0) {
      return null; // No times scheduled, can't calculate
    }

    // Get doses already taken
    final dosesTaken = await _getDosesTaken(medication);

    // Calculate doses remaining
    final dosesRemaining = medication.refillThreshold! - dosesTaken;
    if (dosesRemaining <= 0) {
      // Already out or past threshold, refill needed immediately
      return DateTime.now();
    }

    // Calculate days until refill needed
    final daysUntilRefill = (dosesRemaining / dosesPerDay).ceil();

    // Calculate refill date from today
    final refillDate = DateTime.now().add(Duration(days: daysUntilRefill));

    return refillDate;
  }

  /// Get count of doses taken for a medication
  Future<int> _getDosesTaken(Medication medication) async {
    final logs = await _logsRepository.getLogsForMedication(medication.id);

    // Filter logs to only include those after start date and only "taken" doses
    return logs
        .where((log) => 
            log.status == MedEventStatus.taken && 
            (log.timestamp.isAfter(medication.startDate) || 
             log.timestamp.isAtSameMomentAs(medication.startDate)))
        .length;
  }

  /// Check if refill reminder should be triggered
  /// Returns true if remaining doses <= 7 days worth (or configured threshold)
  Future<bool> checkRefillNeeded(Medication medication, {int daysWarning = 7}) async {
    final refillDate = await calculateRefillDate(medication);
    if (refillDate == null) {
      return false;
    }

    final now = DateTime.now();
    final warningDate = now.add(Duration(days: daysWarning));

    // Check if refill date is within warning period
    return refillDate.isBefore(warningDate) || refillDate.isAtSameMomentAs(warningDate);
  }

  /// Get estimated refill date as a formatted string
  Future<String?> getRefillDateString(Medication medication) async {
    final refillDate = await calculateRefillDate(medication);
    if (refillDate == null) {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final refillDay = DateTime(refillDate.year, refillDate.month, refillDate.day);

    if (refillDay == today) {
      return 'Today';
    } else if (refillDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${refillDate.day}/${refillDate.month}/${refillDate.year}';
    }
  }
}

