import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';
import '../../logs/providers/logs_providers.dart';
import '../../logs/repository/logs_repository.dart';
import '../../../app/theme/app_theme.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final logsRepo = ref.watch(logsRepositoryProvider);
  return ExportService(logsRepo);
});

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
  }

  Future<void> _exportCSV() async {
    setState(() => _isExporting = true);

    try {
      final exportService = ref.read(exportServiceProvider);
      final filename = 'medication_logs_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final csvContent = await exportService.exportLogsToCSV(
        startDate: _startDate,
        endDate: _endDate,
      );
      await exportService.shareCSV(csvContent, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);

    try {
      final exportService = ref.read(exportServiceProvider);
      final reportContent = await exportService.generateReportSummary(
        startDate: _startDate,
        endDate: _endDate,
      );
      final filename = 'medication_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt';
      await exportService.shareCSV(reportContent, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: isDark ? const Color(0xFF1F2937) : AppTheme.teal500,
        foregroundColor: AppTheme.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                  width: 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Start Date'),
                      subtitle: Text(_startDate != null
                          ? DateFormat('yyyy-MM-dd').format(_startDate!)
                          : 'Not selected'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('End Date'),
                      subtitle: Text(_endDate != null
                          ? DateFormat('yyyy-MM-dd').format(_endDate!)
                          : 'Not selected'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportCSV,
              icon: const Icon(Icons.file_download),
              label: const Text('Export as CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.teal500,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isExporting ? null : _exportReport,
              icon: const Icon(Icons.description),
              label: const Text('Export Summary Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.teal500,
                side: const BorderSide(color: AppTheme.teal500, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (_isExporting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

