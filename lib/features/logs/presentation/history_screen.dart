import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/med_log.dart';
import '../providers/logs_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../medication/providers/medication_providers.dart';
import '../../../utils/navigation_helper.dart';
import '../../../core/models/medication.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logsAsync = ref.watch(logsStreamProvider(today));
    final medicationsAsync = ref.watch(medicationsStreamProvider);

    // Calculate 7-day adherence based on expected vs taken doses
    final adherenceData = logsAsync.when(
      data: (logs) => medicationsAsync.when(
        data: (medications) {
          final currentNow = DateTime.now();
          final todayMidnight = DateTime(
            currentNow.year,
            currentNow.month,
            currentNow.day,
          );
          final startOfWindow = todayMidnight.subtract(const Duration(days: 6));

          // Get active medications
          final activeMeds = medications.where((med) {
            if (med.startDate.isAfter(todayMidnight)) return false;
            if (med.endDate != null && med.endDate!.isBefore(startOfWindow)) {
              return false;
            }
            return true;
          }).toList();

          // Calculate expected doses for the week (including today)
          int expectedDoses = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = startOfWindow.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));

              if (med.startDate.isBefore(dayEnd) &&
                  (med.endDate == null || !med.endDate!.isBefore(dayStart))) {
                expectedDoses += med.timesPerDay.length;
              }
            }
          }

          // Count taken doses - match with scheduled times
          int takenDoses = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = startOfWindow.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));

              if (med.startDate.isBefore(dayEnd) &&
                  (med.endDate == null || !med.endDate!.isBefore(dayStart))) {
                for (final scheduledTime in med.timesPerDay) {
                  final scheduledDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    scheduledTime.hour,
                    scheduledTime.minute,
                  );

                  final hasLog = logs.any(
                    (log) =>
                        log.medicationId == med.id &&
                        log.status == MedEventStatus.taken &&
                        log.timestamp.isAfter(dayStart) &&
                        log.timestamp.isBefore(dayEnd) &&
                        log.scheduledDoseTime.year == scheduledDateTime.year &&
                        log.scheduledDoseTime.month ==
                            scheduledDateTime.month &&
                        log.scheduledDoseTime.day == scheduledDateTime.day &&
                        log.scheduledDoseTime.hour == scheduledDateTime.hour &&
                        log.scheduledDoseTime.minute ==
                            scheduledDateTime.minute,
                  );

                  if (hasLog) {
                    takenDoses++;
                  }
                }
              }
            }
          }

          final percentage = expectedDoses > 0
              ? (takenDoses / expectedDoses * 100).round()
              : 0;

          // Calculate last week for comparison (previous 7-day window)
          final previousWindowStart = startOfWindow.subtract(
            const Duration(days: 7),
          );
          int lastWeekExpected = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = previousWindowStart.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));

              if (med.startDate.isBefore(dayEnd) &&
                  (med.endDate == null || !med.endDate!.isBefore(dayStart))) {
                lastWeekExpected += med.timesPerDay.length;
              }
            }
          }
          int lastWeekTaken = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = previousWindowStart.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));

              if (med.startDate.isBefore(dayEnd) &&
                  (med.endDate == null || !med.endDate!.isBefore(dayStart))) {
                for (final scheduledTime in med.timesPerDay) {
                  final scheduledDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    scheduledTime.hour,
                    scheduledTime.minute,
                  );

                  final hasLog = logs.any(
                    (log) =>
                        log.medicationId == med.id &&
                        log.status == MedEventStatus.taken &&
                        log.timestamp.isAfter(dayStart) &&
                        log.timestamp.isBefore(dayEnd) &&
                        log.scheduledDoseTime.year == scheduledDateTime.year &&
                        log.scheduledDoseTime.month ==
                            scheduledDateTime.month &&
                        log.scheduledDoseTime.day == scheduledDateTime.day &&
                        log.scheduledDoseTime.hour == scheduledDateTime.hour &&
                        log.scheduledDoseTime.minute ==
                            scheduledDateTime.minute,
                  );

                  if (hasLog) {
                    lastWeekTaken++;
                  }
                }
              }
            }
          }
          final lastWeekPercentage = lastWeekExpected > 0
              ? (lastWeekTaken / lastWeekExpected * 100).round()
              : 0;

          return {
            'percentage': percentage,
            'lastWeek': lastWeekPercentage,
            'taken': takenDoses,
            'expected': expectedDoses,
          };
        },
        loading: () => {
          'percentage': 0,
          'lastWeek': 0,
          'taken': 0,
          'expected': 0,
        },
        error: (error, stack) {
          debugPrint('Error loading medications for adherence: $error');
          return {'percentage': 0, 'lastWeek': 0, 'taken': 0, 'expected': 0};
        },
      ),
      loading: () => {
        'percentage': 0,
        'lastWeek': 0,
        'taken': 0,
        'expected': 0,
      },
      error: (error, stack) {
        debugPrint('Error loading logs for adherence: $error');
        return {'percentage': 0, 'lastWeek': 0, 'taken': 0, 'expected': 0};
      },
    );

    // Calculate current streak - consecutive days with at least one taken dose
    final streakData = logsAsync.when(
      data: (logs) {
        int streak = 0;
        final currentNow = DateTime.now();
        final today = DateTime(
          currentNow.year,
          currentNow.month,
          currentNow.day,
        );

        for (int i = 0; i < 365; i++) {
          final date = today.subtract(Duration(days: i));
          final dayStart = DateTime(date.year, date.month, date.day);
          final dayEnd = dayStart.add(const Duration(days: 1));

          final dayLogs = logs
              .where(
                (log) =>
                    log.timestamp.isAfter(dayStart) &&
                    log.timestamp.isBefore(dayEnd) &&
                    log.status == MedEventStatus.taken,
              )
              .toList();

          if (dayLogs.isEmpty) {
            break;
          } else {
            streak++;
          }
        }
        return streak;
      },
      loading: () => 0,
      error: (error, stack) {
        debugPrint('Error calculating streak: $error');
        return 0;
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1F2937), Color(0xFF111827)],
                      )
                    : AppTheme.tealGradient,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.arrowLeft, color: AppTheme.white),
                    onPressed: () => context.safePop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      'History & Progress',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '7-Day Adherence',
                      value: '${adherenceData['percentage']}%',
                      subtitle:
                          adherenceData['lastWeek']! >
                              adherenceData['percentage']!
                          ? '${adherenceData['lastWeek']! - adherenceData['percentage']!}% from last week'
                          : '+${adherenceData['percentage']! - adherenceData['lastWeek']!}% from last week',
                      color: AppTheme.teal500,
                      icon: AppIcons.barChart3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Current Streak',
                      value: '$streakData days',
                      subtitle: streakData > 0
                          ? 'Keep it going!'
                          : 'Start your streak today',
                      color: AppTheme.blue500,
                      icon: AppIcons.trendingUp,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content - Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Adherence Rate Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F2937)
                            : AppTheme.white,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adherence Rate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${adherenceData['percentage']}%',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.teal500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${adherenceData['taken']}/${adherenceData['expected']} doses',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? AppTheme.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : AppTheme.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.teal500.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${adherenceData['percentage']}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.teal500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Calendar View
                    Text(
                      'Adherence Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CalendarView(now: now),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _LegendItem(
                          color: AppTheme.teal500,
                          label: '100% adherence',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: AppTheme.yellow500,
                          label: 'Partial adherence',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: AppTheme.blue200,
                          label: 'Pending doses',
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        _LegendItem(
                          color: AppTheme.red500,
                          label: 'Missed doses',
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Activity
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    logsAsync.when(
                      data: (logs) {
                        if (logs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : AppTheme.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.gray700
                                    : AppTheme.gray200,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.bell,
                                    size: 48,
                                    color: isDark
                                        ? AppTheme.gray400
                                        : AppTheme.gray400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No recent activity',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.white
                                          : AppTheme.gray900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Log your medication doses to see activity here',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.white.withValues(
                                              alpha: 0.6,
                                            )
                                          : AppTheme.gray600,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final recent = logs.take(5).toList();
                        return Column(
                          children: recent
                              .map(
                                (log) => _ActivityItem(
                                  log: log,
                                  isDark: isDark,
                                  medications: medicationsAsync.when(
                                    data: (meds) => meds,
                                    loading: () => [],
                                    error: (_, __) => [],
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.teal500,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading activity...',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.white
                                      : AppTheme.gray900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      error: (error, stack) {
                        debugPrint('Error loading recent activity: $error');
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : AppTheme.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  AppIcons.alertCircle,
                                  size: 48,
                                  color: AppTheme.red500,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Error loading activity',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.white
                                        : AppTheme.gray900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Medication History List
                    Text(
                      'Medication History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    logsAsync.when(
                      data: (logs) => medicationsAsync.when(
                        data: (medications) {
                          if (logs.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F2937)
                                    : AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.gray700
                                      : AppTheme.gray200,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.pill,
                                      size: 48,
                                      color: isDark
                                          ? AppTheme.gray400
                                          : AppTheme.gray400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No medication history',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.white
                                            : AppTheme.gray900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your medication logs will appear here',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.white.withValues(
                                                alpha: 0.6,
                                              )
                                            : AppTheme.gray600,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Create a map for quick medication lookup
                          final medicationMap = {
                            for (var med in medications) med.id: med,
                          };

                          return Column(
                            children: logs.map((log) {
                              final medication =
                                  medicationMap[log.medicationId];
                              return _HistoryItem(
                                log: log,
                                medication: medication,
                                isDark: isDark,
                              );
                            }).toList(),
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.teal500,
                            ),
                          ),
                        ),
                        error: (error, stack) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading medications',
                            style: TextStyle(
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                            ),
                          ),
                        ),
                      ),
                      loading: () => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.teal500,
                          ),
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading history',
                          style: TextStyle(
                            color: isDark ? AppTheme.white : AppTheme.gray900,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  final DateTime now;

  const _CalendarView({required this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referenceDate = DateTime(now.year, now.month, now.day);
    final logsAsync = ref.watch(logsStreamProvider(referenceDate));
    final medicationsAsync = ref.watch(medicationsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: logsAsync.when(
        data: (logs) => medicationsAsync.when(
          data: (medications) {
            // Generate calendar grid for current month
            final firstDay = DateTime(now.year, now.month, 1);
            final startDate = firstDay.subtract(
              Duration(days: firstDay.weekday % 7),
            );

            return Column(
              children: [
                // Month header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(now),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Weekday headers
                Row(
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Calendar grid
                ...List.generate(6, (weekIndex) {
                  return Row(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(
                        Duration(days: weekIndex * 7 + dayIndex),
                      );
                      final isCurrentMonth = date.month == now.month;
                      final isToday =
                          date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;

                      // Calculate adherence for this day
                      final dayStart = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                      final dayEnd = dayStart.add(const Duration(days: 1));

                      int expectedDoses = 0;
                      for (final med in medications) {
                        if (med.startDate.isBefore(dayEnd) &&
                            (med.endDate == null ||
                                !med.endDate!.isBefore(dayStart))) {
                          expectedDoses += med.timesPerDay.length;
                        }
                      }

                      final isFuture = date.isAfter(referenceDate);
                      final takenDoses = isFuture
                          ? 0
                          : logs
                                .where(
                                  (log) =>
                                      log.timestamp.isAfter(dayStart) &&
                                      log.timestamp.isBefore(dayEnd) &&
                                      log.status == MedEventStatus.taken,
                                )
                                .length;

                      final percentage = expectedDoses > 0 && !isFuture
                          ? (takenDoses / expectedDoses)
                          : 0.0;

                      Color dayColor;
                      if (!isCurrentMonth) {
                        dayColor = isDark ? AppTheme.gray700 : AppTheme.gray100;
                      } else if (expectedDoses == 0) {
                        dayColor = isDark ? AppTheme.gray700 : AppTheme.gray200;
                      } else if (isFuture) {
                        dayColor = AppTheme.blue200;
                      } else if (percentage >= 1.0) {
                        dayColor = AppTheme.teal500;
                      } else if (percentage > 0) {
                        dayColor = AppTheme.yellow500;
                      } else {
                        dayColor = AppTheme.red500;
                      }

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          height: 40,
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDark ? AppTheme.gray700 : AppTheme.gray100)
                                : dayColor.withValues(
                                    alpha: isCurrentMonth ? 0.3 : 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: AppTheme.teal500, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentMonth
                                    ? (isDark
                                          ? AppTheme.white
                                          : AppTheme.gray900)
                                    : (isDark
                                          ? AppTheme.gray500
                                          : AppTheme.gray400),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Center(
            child: Text(
              'Error loading medications',
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.gray900,
              ),
            ),
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (_, __) => Center(
          child: Text(
            'Error loading logs',
            style: TextStyle(color: isDark ? AppTheme.white : AppTheme.gray900),
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final MedLog log;
  final bool isDark;
  final List<Medication> medications;

  const _ActivityItem({
    required this.log,
    required this.isDark,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final isToday =
        log.timestamp.year == DateTime.now().year &&
        log.timestamp.month == DateTime.now().month &&
        log.timestamp.day == DateTime.now().day;
    final isTaken = log.status == MedEventStatus.taken;
    final medication = medications.firstWhere(
      (med) => med.id == log.medicationId,
      orElse: () => Medication(
        id: '',
        name: 'Unknown Medication',
        dosage: '',
        timesPerDay: [],
        frequency: 'daily',
        startDate: DateTime.now(),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTaken
                  ? AppTheme.teal100
                  : (isDark ? AppTheme.gray700 : AppTheme.gray100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTaken ? AppIcons.check : AppIcons.x,
              color: isTaken ? AppTheme.teal600 : AppTheme.gray400,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isToday
                      ? 'Today, ${DateFormat('h:mm a').format(log.timestamp)}'
                      : DateFormat('MMM dd, h:mm a').format(log.timestamp),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.teal100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Taken',
                style: TextStyle(
                  color: AppTheme.teal700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final MedLog log;
  final Medication? medication;
  final bool isDark;

  const _HistoryItem({
    required this.log,
    this.medication,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = log.status == MedEventStatus.taken;
    final medicationName = medication?.name ?? 'Unknown Medication';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTaken ? AppIcons.check : AppIcons.x,
            color: isTaken ? AppTheme.teal500 : AppTheme.gray400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicationName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • h:mm a').format(log.timestamp),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray600,
                    fontSize: 12,
                  ),
                ),
                if (medication != null && medication!.dosage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    medication!.dosage,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.white.withValues(alpha: 0.5)
                          : AppTheme.gray500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isTaken
                  ? AppTheme.teal100
                  : (isDark ? AppTheme.gray700 : AppTheme.gray100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              log.status.name.toUpperCase(),
              style: TextStyle(
                color: isTaken
                    ? AppTheme.teal700
                    : (isDark ? AppTheme.gray400 : AppTheme.gray700),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.white : AppTheme.gray700,
          ),
        ),
      ],
    );
  }
}
