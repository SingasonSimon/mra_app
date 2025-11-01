import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/med_log.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final adherenceAsyncValue = ref.watch(todayAdherenceProvider);
    final nextDoseAsyncValue = ref.watch(nextDoseProvider);
    final todayMedsAsync = ref.watch(todayMedicationsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Teal Header Section with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: AppTheme.tealGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()},',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              profileAsync.value?.name ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.teal100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.heart,
                          color: AppTheme.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Today's Adherence Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: adherenceAsyncValue.when(
                      data: (adherence) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Today's Adherence",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    AppIcons.trendingUp,
                                    color: AppTheme.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${adherence.percentage}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${adherence.taken} of ${adherence.total} taken',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: adherence.percentage / 100,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (_, __) => const Text(
                        'Error loading adherence',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Next Dose Reminder Card
                    nextDoseAsyncValue.when(
                      data: (nextDose) {
                        if (nextDose == null) {
                          return const SizedBox.shrink();
                        }
                        final cardBg = isDark ? const Color(0xFF1F2937) : AppTheme.white;
                        final cardBorder = isDark ? AppTheme.gray700 : AppTheme.blue200;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorder, width: 1),
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
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.blue50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  AppIcons.clock,
                                  color: AppTheme.blue600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next dose in ${nextDose.minutesRemaining} minutes',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${nextDose.medication.name} ${nextDose.medication.dosage} at ${nextDose.formattedTime}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppTheme.white.withValues(alpha: 0.6)
                                            : AppTheme.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: AppIcons.plus,
                            label: 'Add Med',
                            color: AppTheme.teal500,
                            onTap: () => context.push('/medications/add'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: AppIcons.barChart3,
                            label: 'History',
                            color: AppTheme.blue500,
                            onTap: () => context.push('/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: AppIcons.phone,
                            label: 'Emergency',
                            color: AppTheme.red500,
                            onTap: () => context.push('/emergency'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Today's Medication Section
                    Text(
                      "Today's Medication",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    todayMedsAsync.when(
                      data: (meds) {
                        if (meds.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  AppIcons.pill,
                                  size: 48,
                                  color: AppTheme.gray400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No medications scheduled for today',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.white.withValues(alpha: 0.6)
                                        : AppTheme.gray600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: meds.map((med) => _MedicationCard(
                            medication: med.medication,
                            scheduledTime: med.scheduledTime,
                            status: med.status,
                            onMarkTaken: () {
                              // TODO: Implement mark as taken
                              context.push('/logs/${med.medication.id}');
                            },
                          )).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('Error: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final DateTime scheduledTime;
  final MedEventStatus status;
  final VoidCallback onMarkTaken;

  const _MedicationCard({
    required this.medication,
    required this.scheduledTime,
    required this.status,
    required this.onMarkTaken,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = status == MedEventStatus.taken;
    final isUpcoming = scheduledTime.isAfter(DateTime.now());
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isTaken ? AppTheme.successBg : (isUpcoming ? AppTheme.blue50 : AppTheme.gray100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTaken ? AppIcons.check : AppIcons.alertCircle,
              color: isTaken ? AppTheme.successText : (isUpcoming ? AppTheme.blue600 : AppTheme.gray500),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    medication.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${medication.dosage} • $timeStr',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.white.withValues(alpha: 0.6)
                          : AppTheme.gray600,
                    ),
                  ),
              ],
            ),
          ),
          if (isTaken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Taken',
                style: TextStyle(
                  color: AppTheme.successTextDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isUpcoming)
            ElevatedButton(
              onPressed: onMarkTaken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue500,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Mark Taken',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
