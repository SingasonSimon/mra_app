import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/med_log.dart';
import '../../logs/repository/logs_repository.dart';
import 'package:intl/intl.dart';

class ExportService {
  final LogsRepository _logsRepository;

  ExportService(this._logsRepository);

  Future<String> exportLogsToCSV({DateTime? startDate, DateTime? endDate}) async {
    final logs = await _logsRepository.watchLogs(
      startDate: startDate,
      endDate: endDate,
    ).first;

    final List<List<dynamic>> csvData = [
      ['Date', 'Time', 'Medication ID', 'Status', 'Scheduled Time', 'Notes'],
    ];

    for (final log in logs) {
      csvData.add([
        DateFormat('yyyy-MM-dd').format(log.timestamp),
        DateFormat('HH:mm:ss').format(log.timestamp),
        log.medicationId,
        log.status.name,
        DateFormat('yyyy-MM-dd HH:mm').format(log.scheduledDoseTime),
        log.notes ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return csvString;
  }

  Future<File> saveCSVToFile(String csvContent, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csvContent);
    return file;
  }

  Future<void> shareCSV(String csvContent, String filename) async {
    final file = await saveCSVToFile(csvContent, filename);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Medication Logs Export',
      text: 'Medication logs exported from Medical Reminder App',
    );
  }

  Future<String> generateReportSummary({DateTime? startDate, DateTime? endDate}) async {
    final logs = await _logsRepository.watchLogs(
      startDate: startDate,
      endDate: endDate,
    ).first;

    final taken = logs.where((log) => log.status == MedEventStatus.taken).length;
    final snoozed = logs.where((log) => log.status == MedEventStatus.snoozed).length;
    final skipped = logs.where((log) => log.status == MedEventStatus.skipped).length;
    final total = logs.length;
    final percentage = total > 0 ? (taken / total * 100) : 0.0;

    final buffer = StringBuffer();
    buffer.writeln('MEDICATION REMINDER APP - REPORT');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Logs: $total');
    buffer.writeln('Taken: $taken');
    buffer.writeln('Snoozed: $snoozed');
    buffer.writeln('Skipped: $skipped');
    buffer.writeln('Adherence Rate: ${percentage.toStringAsFixed(1)}%');
    buffer.writeln('');
    buffer.writeln('DETAILED LOGS');
    buffer.writeln('Date,Time,Medication ID,Status,Scheduled Time,Notes');

    for (final log in logs) {
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(log.timestamp)},'
        '${DateFormat('HH:mm:ss').format(log.timestamp)},'
        '${log.medicationId},'
        '${log.status.name},'
        '${DateFormat('yyyy-MM-dd HH:mm').format(log.scheduledDoseTime)},'
        '${log.notes ?? ''}',
      );
    }

    return buffer.toString();
  }
}

