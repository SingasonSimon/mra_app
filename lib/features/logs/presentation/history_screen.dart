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
import 'dart:math' as math;

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final logsAsync = ref.watch(logsStreamProvider(now));
    final medicationsAsync = ref.watch(medicationsStreamProvider);

    // Calculate 7-day adherence based on expected vs taken doses
    final adherenceData = logsAsync.maybeWhen(
      data: (logs) => medicationsAsync.maybeWhen(
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
              // Check if medication is active on this date
              if (med.startDate.isBefore(date) || med.startDate.isAtSameMomentAs(date)) {
                if (med.endDate == null || med.endDate!.isAfter(date) || med.endDate!.isAtSameMomentAs(date)) {
                  expectedDoses += med.timesPerDay.length;
                }
              }
            }
          }
          
          // Count taken doses - match with scheduled times
          int takenDoses = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = weekAgo.add(Duration(days: day));
              final dayStart = DateTime(date.year, date.month, date.day);
              final dayEnd = dayStart.add(const Duration(days: 1));
              
              // Check if medication is active on this date
              if (med.startDate.isBefore(dayEnd) && (med.endDate == null || med.endDate!.isAfter(dayStart))) {
                // For each scheduled time, check if there's a taken log
                for (final scheduledTime in med.timesPerDay) {
                  final scheduledDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    scheduledTime.hour,
                    scheduledTime.minute,
                  );
                  
                  // Check if there's a log for this scheduled time
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
          
          // Fallback: if matching didn't work, use simple count (less accurate)
          if (takenDoses == 0) {
            takenDoses = logs.where((log) => 
              log.timestamp.isAfter(weekAgo) && 
              log.status == MedEventStatus.taken
            ).length;
          }
          
          final percentage = expectedDoses > 0 ? (takenDoses / expectedDoses * 100).round() : 0;
          
          // Calculate last week for comparison
          final twoWeeksAgo = weekAgo.subtract(const Duration(days: 7));
          int lastWeekExpected = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = twoWeeksAgo.add(Duration(days: day));
              if (med.startDate.isBefore(date) || med.startDate.isAtSameMomentAs(date)) {
                if (med.endDate == null || med.endDate!.isAfter(date) || med.endDate!.isAtSameMomentAs(date)) {
                  lastWeekExpected += med.timesPerDay.length.toInt();
                }
              }
            }
          }
          // Calculate last week taken doses with proper matching
          int lastWeekTaken = 0;
          for (final med in activeMeds) {
            for (int day = 0; day < 7; day++) {
              final date = twoWeeksAgo.add(Duration(days: day));
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
                    lastWeekTaken++;
                  }
                }
              }
            }
          }
          
          // Fallback
          if (lastWeekTaken == 0) {
            lastWeekTaken = logs.where((log) => 
              log.timestamp.isAfter(twoWeeksAgo) && 
              log.timestamp.isBefore(weekAgo) &&
              log.status == MedEventStatus.taken
            ).length;
          }
          final lastWeekPercentage = lastWeekExpected > 0 ? (lastWeekTaken / lastWeekExpected * 100).round() : 0;
          
          return {'percentage': percentage, 'lastWeek': lastWeekPercentage};
        },
        orElse: () => {'percentage': 0, 'lastWeek': 0},
      ),
      orElse: () => {'percentage': 0, 'lastWeek': 0},
    );

    // Calculate current streak - consecutive days with at least one taken dose
    final streakData = logsAsync.maybeWhen(
      data: (logs) {
        int streak = 0;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Start from today and work backwards
        // Streak continues as long as each day has at least one taken dose
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
            // Found a day with no taken doses - streak ends here
            // If it's today (i == 0), streak is 0, otherwise streak is i
            break;
          } else {
            streak++;
          }
        }
        return streak;
      },
      orElse: () => 0,
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
                  const SizedBox(width: 48), // Balance spacing
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
                      subtitle: '+${(adherenceData['percentage'] as int) - (adherenceData['lastWeek'] as int)}% from last week',
                      color: AppTheme.teal500,
                      icon: AppIcons.trendingUp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Current Streak',
                      value: '$streakData days',
                      subtitle: 'Keep it going!',
                      color: AppTheme.blue500,
                      icon: AppIcons.trendingUp,
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: isDark ? AppTheme.white : AppTheme.gray900,
                unselectedLabelColor: isDark ? AppTheme.gray400 : AppTheme.gray700,
                tabs: const [
                  Tab(text: 'Chart'),
                  Tab(text: 'Calendar'),
                  Tab(text: 'List'),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ChartView(
                    selectedPeriod: _selectedPeriod, 
                    onPeriodChanged: (period) {
                      setState(() => _selectedPeriod = period);
                    },
                  ),
                  _CalendarView(),
                  _ListView(),
                ],
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

class _ChartView extends ConsumerWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const _ChartView({
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final logsAsync = ref.watch(logsStreamProvider(now));
    final medicationsAsync = ref.watch(medicationsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adherence Rate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedPeriod,
                      dropdownColor: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                      items: ['This Week', 'This Month', 'Last 3 Months'].map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(
                            period,
                            style: TextStyle(
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) onPeriodChanged(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: logsAsync.when(
                    data: (logs) {
                      return medicationsAsync.when(
                        data: (medications) {
                        // Calculate daily adherence for this week
                        final currentNow = DateTime.now();
                        final weekData = List.generate(7, (index) {
                          final date = currentNow.subtract(Duration(days: 6 - index));
                          final dayStart = DateTime(date.year, date.month, date.day);
                          final dayEnd = dayStart.add(const Duration(days: 1));
                          
                          // Get expected doses for this day
                          int expectedDoses = 0;
                          for (final med in medications) {
                            if (med.startDate.isBefore(dayEnd) && (med.endDate == null || med.endDate!.isAfter(dayStart))) {
                              expectedDoses += med.timesPerDay.length;
                            }
                          }
                          
                          // Get taken doses for this day
                          final takenDoses = logs.where((log) =>
                            log.timestamp.isAfter(dayStart) &&
                            log.timestamp.isBefore(dayEnd) &&
                            log.status == MedEventStatus.taken
                          ).length;
                          
                          final percentage = expectedDoses > 0 ? (takenDoses / expectedDoses * 100).round() : 0;
                          return {'day': DateFormat('E').format(date).substring(0, 3), 'value': percentage};
                        });

                        // Show empty state if no medications or no data
                        if (medications.isEmpty || weekData.every((d) => (d['value'] as int) == 0)) {
                          return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                                AppIcons.barChart3,
                                size: 48,
                                color: isDark ? AppTheme.gray400 : AppTheme.gray400,
                              ),
                              const SizedBox(height: 12),
                        Text(
                                medications.isEmpty 
                                    ? 'No medications yet' 
                                    : 'No adherence data yet',
                                style: TextStyle(
                                  color: isDark ? AppTheme.white : AppTheme.gray900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                        Text(
                                medications.isEmpty
                                    ? 'Add medications to track adherence'
                                    : 'Log your medication doses to see trends',
                                style: TextStyle(
                                  color: isDark 
                                      ? AppTheme.white.withValues(alpha: 0.6)
                                      : AppTheme.gray600,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        }
                        
                          return _SimpleLineChart(data: weekData, isDark: isDark);
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
                                  'Loading medications...',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.white : AppTheme.gray900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        error: (error, stack) {
                          debugPrint('Error loading medications: $error');
                          return Center(
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
                                  'Error loading medications',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.white : AppTheme.gray900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
                              'Loading logs...',
                              style: TextStyle(
                                color: isDark ? AppTheme.white : AppTheme.gray900,
                                  ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    error: (error, stack) {
                      debugPrint('Error loading logs: $error');
                      return Center(
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
                              'Error loading chart data',
                              style: TextStyle(
                                color: isDark ? AppTheme.white : AppTheme.gray900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                    color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppTheme.gray700 : AppTheme.gray200,
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
                          color: isDark ? AppTheme.gray400 : AppTheme.gray400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activity',
                          style: TextStyle(
                            color: isDark ? AppTheme.white : AppTheme.gray900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log your medication doses to see activity here',
                          style: TextStyle(
                            color: isDark 
                                ? AppTheme.white.withValues(alpha: 0.6)
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
                children: recent.map((log) => _ActivityItem(log: log, isDark: isDark)).toList(),
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
                        color: isDark ? AppTheme.white : AppTheme.gray900,
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
                  color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.gray700 : AppTheme.gray200,
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
                          color: isDark ? AppTheme.white : AppTheme.gray900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final logsAsync = ref.watch(logsStreamProvider(now));
    final medicationsAsync = ref.watch(medicationsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adherence Calendar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.white : AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
              data: (logs) => medicationsAsync.maybeWhen(
                data: (medications) {
                
                // Generate calendar grid for current month
                final firstDay = DateTime(now.year, now.month, 1);
                final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));
                
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
                          final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                          final isCurrentMonth = date.month == now.month;
                          final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                          
                          // Calculate adherence for this day
                          final dayStart = DateTime(date.year, date.month, date.day);
                          final dayEnd = dayStart.add(const Duration(days: 1));
                          
                          int expectedDoses = 0;
                          for (final med in medications) {
                            if (med.startDate.isBefore(dayEnd) && (med.endDate == null || med.endDate!.isAfter(dayStart))) {
                              expectedDoses += med.timesPerDay.length;
                            }
                          }
                          
                          final takenDoses = logs.where((log) =>
                            log.timestamp.isAfter(dayStart) &&
                            log.timestamp.isBefore(dayEnd) &&
                            log.status == MedEventStatus.taken
                          ).length;
                          
                          final percentage = expectedDoses > 0 ? (takenDoses / expectedDoses) : 0.0;
                          
                          Color dayColor;
                          if (!isCurrentMonth) {
                            dayColor = isDark ? AppTheme.gray700 : AppTheme.gray100;
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
                                    : dayColor.withValues(alpha: isCurrentMonth ? 0.3 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: isToday ? Border.all(color: AppTheme.teal500, width: 2) : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrentMonth 
                                        ? (isDark ? AppTheme.white : AppTheme.gray900)
                                        : (isDark ? AppTheme.gray500 : AppTheme.gray400),
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
                orElse: () => const Center(child: CircularProgressIndicator()),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Error loading logs',
                  style: TextStyle(color: isDark ? AppTheme.white : AppTheme.gray900),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _LegendItem(color: AppTheme.teal500, label: '100% adherence', isDark: isDark),
              const SizedBox(width: 16),
              _LegendItem(color: AppTheme.yellow500, label: 'Partial adherence', isDark: isDark),
              const SizedBox(width: 16),
              _LegendItem(color: AppTheme.red500, label: 'Missed doses', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final logsAsync = ref.watch(logsStreamProvider(now));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Text(
              'No logs found',
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.gray900,
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final isTaken = log.status == MedEventStatus.taken;
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
                          'Medication Log',
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
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'Error',
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.gray900,
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final MedLog log;
  final bool isDark;

  const _ActivityItem({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isToday = log.timestamp.year == DateTime.now().year &&
        log.timestamp.month == DateTime.now().month &&
        log.timestamp.day == DateTime.now().day;
    final isTaken = log.status == MedEventStatus.taken;

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
                  'Medication ${log.status.name}',
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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

class _SimpleLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isDark;

  const _SimpleLineChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    const double chartHeight = 150;
    const double chartWidth = 300;
    const double padding = 20;

    final maxValue = data.map((d) => d['value'] as int).reduce(math.max);
    final minValue = 0;
    final range = maxValue - minValue;

    // Generate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final value = data[i]['value'] as int;
      final x = padding + (chartWidth - 2 * padding) * (i / (data.length - 1));
      final y = padding + (chartHeight - 2 * padding) * (1 - (value - minValue) / range);
      points.add(Offset(x, y));
    }

    return SizedBox(
      height: chartHeight,
      width: chartWidth,
      child: CustomPaint(
        painter: _LineChartPainter(points: points),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('100', style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                  Text('75', style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                  Text('50', style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                  Text('25', style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                  Text('0', style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray600)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((d) => Text(
                d['day'] as String,
                style: TextStyle(fontSize: 10, color: isDark ? AppTheme.gray400 : AppTheme.gray600),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Offset> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = AppTheme.teal500
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw filled area
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height - 20);
    fillPath.lineTo(points.first.dx, size.height - 20);
    fillPath.close();

    // Create teal gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.teal500.withValues(alpha: 0.3),
          AppTheme.teal500.withValues(alpha: 0.0),
        ],
        stops: const [0.05, 0.95],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = AppTheme.teal500);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
