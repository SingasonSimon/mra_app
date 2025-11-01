import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/med_log.dart';
import '../../medication/providers/medication_providers.dart';
import '../providers/logs_providers.dart';
import '../repository/logs_repository.dart';
import '../../../utils/navigation_helper.dart';

class LogMedicationScreen extends ConsumerWidget {
  final String medicationId;

  const LogMedicationScreen({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => context.safePop(),
        ),
        title: const Text('Log Medication'),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      ),
      body: FutureBuilder<Medication?>(
        future: ref.read(medicationRepositoryProvider).getMedication(medicationId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final medication = snapshot.data!;
          final now = DateTime.now();
          final currentTime = TimeOfDay.fromDateTime(now);

          // Find the closest scheduled time
          TimeOfDay? closestTime;
          for (final time in medication.timesPerDay) {
            final timeMinutes = time.hour * 60 + time.minute;
            final currentMinutes = currentTime.hour * 60 + currentTime.minute;

            if (timeMinutes >= currentMinutes - 30) {
              closestTime = time;
              break;
            }
          }

          if (closestTime == null && medication.timesPerDay.isNotEmpty) {
            closestTime = medication.timesPerDay.first;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(
                                Icons.medication,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medication.name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    medication.dosage,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (closestTime != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Scheduled Time: ${closestTime.hour.toString().padLeft(2, '0')}:${closestTime.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'How did you take this medication?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _LogActionButton(
                  icon: Icons.check_circle,
                  label: 'Taken',
                  color: Colors.green,
                  onPressed: () => _logMedication(
                    context,
                    ref,
                    medication,
                    closestTime ?? TimeOfDay.now(),
                    MedEventStatus.taken,
                  ),
                ),
                const SizedBox(height: 12),
                _LogActionButton(
                  icon: Icons.snooze,
                  label: 'Snooze',
                  color: Colors.orange,
                  onPressed: () => _logMedication(
                    context,
                    ref,
                    medication,
                    closestTime ?? TimeOfDay.now(),
                    MedEventStatus.snoozed,
                  ),
                ),
                const SizedBox(height: 12),
                _LogActionButton(
                  icon: Icons.close,
                  label: 'Skip',
                  color: Colors.red,
                  onPressed: () => _logMedication(
                    context,
                    ref,
                    medication,
                    closestTime ?? TimeOfDay.now(),
                    MedEventStatus.skipped,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logMedication(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
    TimeOfDay scheduledTime,
    MedEventStatus status,
  ) async {
    try {
      final logsRepo = ref.read(logsRepositoryProvider);
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      final log = MedLog(
        id: '',
        medicationId: medication.id,
        timestamp: now,
        status: status,
        scheduledDoseTime: scheduledDateTime,
      );

      await logsRepo.logMedicationEvent(log);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medication logged as ${status.name}'),
            backgroundColor: status == MedEventStatus.taken
                ? Colors.green
                : status == MedEventStatus.snoozed
                    ? Colors.orange
                    : Colors.red,
          ),
        );
        // Navigate back safely
        context.safePop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

class _LogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _LogActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

