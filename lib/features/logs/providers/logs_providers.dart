import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/logs_repository.dart';
import '../../../core/models/med_log.dart';

final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  return LogsRepository();
});

final logsStreamProvider = StreamProvider.family<List<MedLog>, DateTime?>((ref, endDate) {
  final repository = ref.watch(logsRepositoryProvider);
  final startDate = endDate?.subtract(const Duration(days: 7));
  return repository.watchLogs(startDate: startDate, endDate: endDate);
});

