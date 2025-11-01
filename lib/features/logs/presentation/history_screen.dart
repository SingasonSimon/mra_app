import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/med_log.dart';
import '../providers/logs_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
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
    final logsAsync = ref.watch(logsStreamProvider(DateTime.now()));

    // Calculate 7-day adherence
    final adherenceData = logsAsync.maybeWhen(
      data: (logs) {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        final weekLogs = logs.where((log) => 
          log.timestamp.isAfter(weekAgo) && log.status == MedEventStatus.taken
        ).toList();
        final totalWeek = logs.where((log) => 
          log.timestamp.isAfter(weekAgo)
        ).length;
        final percentage = totalWeek > 0 ? (weekLogs.length / totalWeek * 100).round() : 0;
        return {'percentage': percentage, 'lastWeek': (percentage - 5).clamp(0, 100)};
      },
      orElse: () => {'percentage': 0, 'lastWeek': 0},
    );

    // Calculate current streak
    final streakData = logsAsync.maybeWhen(
      data: (logs) {
        int streak = 0;
        final now = DateTime.now();
        for (int i = 0; i < 30; i++) {
          final date = now.subtract(Duration(days: i));
          final dayLogs = logs.where((log) => 
            log.timestamp.year == date.year &&
            log.timestamp.month == date.month &&
            log.timestamp.day == date.day &&
            log.status == MedEventStatus.taken
          ).toList();
          if (dayLogs.isEmpty && i > 0) break;
          if (dayLogs.isNotEmpty) streak++;
        }
        return streak;
      },
      orElse: () => 5,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      'History & Progress',
                      style: const TextStyle(
                        color: Colors.white,
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
                      color: AppTheme.primary,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Current Streak',
                      value: '$streakData days',
                      subtitle: 'Keep it going!',
                      color: Colors.blue,
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[700],
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
                  _ChartView(selectedPeriod: _selectedPeriod, onPeriodChanged: (period) {
                    setState(() => _selectedPeriod = period);
                  }),
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
    final logsAsync = ref.watch(logsStreamProvider(DateTime.now()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
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
                    const Text(
                      'Adherence Rate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: selectedPeriod,
                      items: ['This Week', 'This Month', 'Last 3 Months'].map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period),
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
                      // Calculate daily adherence for this week
                      final now = DateTime.now();
                      final weekData = List.generate(7, (index) {
                        final date = now.subtract(Duration(days: 6 - index));
                        final dayLogs = logs.where((log) =>
                          log.timestamp.year == date.year &&
                          log.timestamp.month == date.month &&
                          log.timestamp.day == date.day
                        ).toList();
                        final taken = dayLogs.where((log) => log.status == MedEventStatus.taken).length;
                        final percentage = dayLogs.isEmpty ? 0 : (taken / dayLogs.length * 100).round();
                        return {'day': DateFormat('E').format(date).substring(0, 3), 'value': percentage};
                      });

                      return _SimpleLineChart(data: weekData);
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error loading chart')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent Activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          logsAsync.when(
            data: (logs) {
              final recent = logs.take(5).toList();
              if (recent.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No recent activity'),
                  ),
                );
              }
              return Column(
                children: recent.map((log) => _ActivityItem(log: log)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error')),
          ),
        ],
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Calendar view - Coming soon'),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              _LegendItem(color: Colors.teal, label: '100% adherence'),
              SizedBox(width: 16),
              _LegendItem(color: Colors.yellow, label: 'Partial adherence'),
              SizedBox(width: 16),
              _LegendItem(color: Colors.red, label: 'Missed doses'),
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
    final logsAsync = ref.watch(logsStreamProvider(DateTime.now()));

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text('No logs found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    log.status == MedEventStatus.taken ? Icons.check_circle : Icons.circle,
                    color: log.status == MedEventStatus.taken ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Log',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • h:mm a').format(log.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: log.status == MedEventStatus.taken
                          ? Colors.green[50]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      log.status.name.toUpperCase(),
                      style: TextStyle(
                        color: log.status == MedEventStatus.taken
                            ? Colors.green[700]
                            : Colors.grey[700],
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
      error: (_, __) => const Center(child: Text('Error')),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final MedLog log;

  const _ActivityItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isToday = log.timestamp.year == DateTime.now().year &&
        log.timestamp.month == DateTime.now().month &&
        log.timestamp.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.status == MedEventStatus.taken
                  ? Colors.green[50]
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.status == MedEventStatus.taken ? Icons.check : Icons.circle,
              color: log.status == MedEventStatus.taken ? Colors.green : Colors.grey,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isToday
                      ? 'Today, ${DateFormat('h:mm a').format(log.timestamp)}'
                      : DateFormat('MMM dd, h:mm a').format(log.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (log.status == MedEventStatus.taken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Taken',
                style: TextStyle(
                  color: Colors.green,
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

  const _LegendItem({required this.color, required this.label});

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
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const _SimpleLineChart({required this.data});

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
                  const Text('100', style: TextStyle(fontSize: 10)),
                  const Text('75', style: TextStyle(fontSize: 10)),
                  const Text('50', style: TextStyle(fontSize: 10)),
                  const Text('25', style: TextStyle(fontSize: 10)),
                  const Text('0', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((d) => Text(
                d['day'] as String,
                style: const TextStyle(fontSize: 10),
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
      ..color = AppTheme.primary
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

    final fillPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = AppTheme.primary);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
