import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../logs/providers/logs_providers.dart';
import '../../logs/repository/logs_repository.dart';
import '../../../core/models/med_log.dart';
import '../../../widgets/page_enter_transition.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final logsAsync = ref.watch(logsStreamProvider(now));

    final content = logsAsync.when(
        data: (logs) {
        final weekLogs = logs
            .where((log) => log.timestamp.isAfter(weekAgo))
            .toList();
          final stats = _calculateStats(weekLogs);
          final dailyStats = _calculateDailyStats(weekLogs, weekAgo);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatCard(
                  title: '7-Day Adherence',
                  value: '${stats['percentage'].toStringAsFixed(1)}%',
                  subtitle: '${stats['taken']} of ${stats['total']} doses',
                  color: _getAdherenceColor(stats['percentage'] as double),
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Current Streak',
                  value: '${stats['streak']} days',
                  subtitle: 'Keep it up!',
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  'Daily Adherence',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                            final date = weekAgo.add(
                              Duration(days: value.toInt()),
                            );
                              return Text(
                                DateFormat('E').format(date),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),
                            );
                            },
                          ),
                        ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      ),
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      barGroups: dailyStats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final percentage = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: percentage,
                              color: _getAdherenceColor(percentage),
                              width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Status Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: stats['taken'] as double,
                        title:
                            '${((stats['taken'] as double) / (stats['total'] as double) * 100).toStringAsFixed(0)}%',
                          color: Colors.green,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: stats['snoozed'] as double,
                        title:
                            '${((stats['snoozed'] as double) / (stats['total'] as double) * 100).toStringAsFixed(0)}%',
                          color: Colors.orange,
                          radius: 50,
                        ),
                        PieChartSectionData(
                          value: stats['skipped'] as double,
                        title:
                            '${((stats['skipped'] as double) / (stats['total'] as double) * 100).toStringAsFixed(0)}%',
                          color: Colors.red,
                          radius: 50,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Insights')),
      body: PageEnterTransition(child: content),
    );
  }

  Map<String, dynamic> _calculateStats(List<MedLog> logs) {
    final taken = logs
        .where((log) => log.status == MedEventStatus.taken)
        .length;
    final snoozed = logs
        .where((log) => log.status == MedEventStatus.snoozed)
        .length;
    final skipped = logs
        .where((log) => log.status == MedEventStatus.skipped)
        .length;
    final total = logs.length;
    final percentage = total > 0 ? (taken / total * 100) : 0.0;

    // Calculate streak
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(
          log.timestamp.year,
          log.timestamp.month,
          log.timestamp.day,
        );
        final checkDate = DateTime(date.year, date.month, date.day);
        return logDate.isAtSameMomentAs(checkDate);
      }).toList();

      if (dayLogs.isEmpty) break;
      final dayTaken = dayLogs
          .where((log) => log.status == MedEventStatus.taken)
          .length;
      if (dayTaken > 0) {
        streak++;
      } else {
        break;
      }
    }

    return {
      'taken': taken.toDouble(),
      'snoozed': snoozed.toDouble(),
      'skipped': skipped.toDouble(),
      'total': total.toDouble(),
      'percentage': percentage,
      'streak': streak,
    };
  }

  List<double> _calculateDailyStats(List<MedLog> logs, DateTime startDate) {
    final List<double> dailyPercentages = [];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(
          log.timestamp.year,
          log.timestamp.month,
          log.timestamp.day,
        );
        final checkDate = DateTime(date.year, date.month, date.day);
        return logDate.isAtSameMomentAs(checkDate);
      }).toList();

      if (dayLogs.isEmpty) {
        dailyPercentages.add(0);
      } else {
        final taken = dayLogs
            .where((log) => log.status == MedEventStatus.taken)
            .length;
        dailyPercentages.add((taken / dayLogs.length * 100));
      }
    }
    return dailyPercentages;
  }

  Color _getAdherenceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
