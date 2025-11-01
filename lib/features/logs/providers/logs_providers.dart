import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/logs_repository.dart';
import '../../../core/models/med_log.dart';

final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  return LogsRepository();
});

final logsStreamProvider = StreamProvider.family<List<MedLog>, DateTime?>((ref, endDate) {
  final repository = ref.watch(logsRepositoryProvider);
  // Fetch logs for the last 90 days to support calendar and history views
  final startDate = (endDate ?? DateTime.now()).subtract(const Duration(days: 90));
  return repository.watchLogs(startDate: startDate, endDate: endDate);
});

