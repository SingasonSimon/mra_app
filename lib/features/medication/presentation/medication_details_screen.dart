import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/med_log.dart';
import '../../../app/theme/app_theme.dart';
import '../../../widgets/page_enter_transition.dart';
import '../../../utils/navigation_helper.dart';
import '../../logs/providers/logs_providers.dart';
import '../../logs/repository/logs_repository.dart';
import '../providers/medication_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class MedicationDetailsScreen extends ConsumerStatefulWidget {
  final Medication medication;
  final DateTime? scheduledTime;

  const MedicationDetailsScreen({
    super.key,
    required this.medication,
    this.scheduledTime,
  });

  @override
  ConsumerState<MedicationDetailsScreen> createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState
    extends ConsumerState<MedicationDetailsScreen> {
  bool _isLoading = false;

  Future<void> _markAsTaken() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final logsRepo = ref.read(logsRepositoryProvider);
      final now = DateTime.now();
      final scheduledDateTime = widget.scheduledTime ??
          DateTime(
            now.year,
            now.month,
            now.day,
            widget.medication.timesPerDay.first.hour,
            widget.medication.timesPerDay.first.minute,
          );

      final log = MedLog(
        id: '',
        medicationId: widget.medication.id,
        timestamp: now,
        status: MedEventStatus.taken,
        scheduledDoseTime: scheduledDateTime,
      );

      await logsRepo.logMedicationEvent(log);

      // Invalidate dashboard providers to refresh the UI
      ref.invalidate(todayMedicationsProvider);
      ref.invalidate(todayAdherenceProvider);
      ref.invalidate(nextDoseProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication marked as taken'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsSkipped() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final logsRepo = ref.read(logsRepositoryProvider);
      final now = DateTime.now();
      final scheduledDateTime = widget.scheduledTime ??
          DateTime(
            now.year,
            now.month,
            now.day,
            widget.medication.timesPerDay.first.hour,
            widget.medication.timesPerDay.first.minute,
          );

      final log = MedLog(
        id: '',
        medicationId: widget.medication.id,
        timestamp: now,
        status: MedEventStatus.skipped,
        scheduledDoseTime: scheduledDateTime,
      );

      await logsRepo.logMedicationEvent(log);

      // Invalidate dashboard providers to refresh the UI
      ref.invalidate(todayMedicationsProvider);
      ref.invalidate(todayAdherenceProvider);
      ref.invalidate(nextDoseProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication marked as skipped'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markDosageComplete() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final logsRepo = ref.read(logsRepositoryProvider);
      final now = DateTime.now();

      // Mark all scheduled doses for today as taken
      for (final time in widget.medication.timesPerDay) {
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        final log = MedLog(
          id: '',
          medicationId: widget.medication.id,
          timestamp: now,
          status: MedEventStatus.taken,
          scheduledDoseTime: scheduledDateTime,
        );

        await logsRepo.logMedicationEvent(log);
      }

      // Invalidate dashboard providers to refresh the UI
      ref.invalidate(todayMedicationsProvider);
      ref.invalidate(todayAdherenceProvider);
      ref.invalidate(nextDoseProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All doses for today marked as complete'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final localizations = MaterialLocalizations.of(context);
    final use24Hour = mediaQuery.alwaysUse24HourFormat;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Medication Details'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrowLeft),
          onPressed: () => context.safePop(),
        ),
      ),
      body: PageEnterTransition(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medication Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.tealGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            AppIcons.pill,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.medication.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.medication.dosage,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Dosage Times
              Text(
                'Scheduled Times',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.medication.timesPerDay.map((time) {
                final formattedTime = localizations.formatTimeOfDay(
                  time,
                  alwaysUse24HourFormat: use24Hour,
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.gray700
                          : AppTheme.gray200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.clock,
                        color: AppTheme.teal500,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.white
                              : AppTheme.gray900,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (widget.medication.notes != null &&
                  widget.medication.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.gray700
                          : AppTheme.gray200,
                    ),
                  ),
                  child: Text(
                    widget.medication.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.white.withValues(alpha: 0.8)
                          : AppTheme.gray700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              // Action Buttons
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 12),
              // Mark Taken Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _markAsTaken,
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'Mark as Taken',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.teal500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Mark Skipped Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _markAsSkipped,
                  icon: const Icon(Icons.cancel, size: 24),
                  label: const Text(
                    'Mark as Skipped',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.orange600,
                    side: const BorderSide(color: AppTheme.orange600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Mark All Doses Complete Button
              if (widget.medication.timesPerDay.length > 1)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _markDosageComplete,
                    icon: const Icon(Icons.done_all, size: 24),
                    label: const Text(
                      'Mark All Doses Complete',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

