import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/medication.dart';
import '../../../core/models/med_log.dart';
import '../../logs/providers/logs_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final adherenceAsyncValue = ref.watch(todayAdherenceProvider);
    final nextDoseAsyncValue = ref.watch(nextDoseProvider);
    final todayMedsAsync = ref.watch(todayMedicationsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Prevent back button from closing app when on dashboard
    return PopScope(
      canPop: false, // Prevent popping - this keeps the app open
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // This callback is called when a pop is attempted
        // Since canPop is false, the pop won't happen
        // But we log it for debugging
        debugPrint('Back button pressed on dashboard - prevented app closure');
      },
      child: Scaffold(
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
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Today's Adherence Card
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
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
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
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
                                    _NextDoseCountdown(
                                      scheduledTime: nextDose.scheduledTime,
                                    ),
                                    const SizedBox(height: 4),
                                    Builder(
                                      builder: (context) {
                                        final localizations = MaterialLocalizations.of(context);
                                        final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
                                        final timeOfDay = TimeOfDay.fromDateTime(nextDose.scheduledTime);
                                        final formattedTime = localizations.formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: use24Hour);
                                        return Text(
                                          '${nextDose.medication.name} ${nextDose.medication.dosage} at $formattedTime',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppTheme.white.withValues(alpha: 0.6)
                                                : AppTheme.gray600,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    // Quick Actions
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
                            onTap: () => context.go('/history'),
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
                    const SizedBox(height: 20),
                    // Today's Medication
                    Text(
                      "Today's Medication",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    todayMedsAsync.when(
                      data: (medications) {
                        if (medications.isEmpty) {
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
                                    AppIcons.pill,
                                    size: 48,
                                    color: isDark ? AppTheme.gray400 : AppTheme.gray400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No medications scheduled for today',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.white : AppTheme.gray900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: medications.map((med) => InkWell(
                            onTap: () => context.push(
                              '/medications/${med.medication.id}/details',
                              extra: {'medication': med.medication, 'scheduledTime': med.scheduledTime},
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: _MedicationCard(
                            medication: med.medication,
                            scheduledTime: med.scheduledTime,
                            status: med.status,
                            isDark: isDark,
                            ),
                          )).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
      ),
    );
  }

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
}

// Dynamic countdown widget for next dose
class _NextDoseCountdown extends StatefulWidget {
  final DateTime scheduledTime;

  const _NextDoseCountdown({
    required this.scheduledTime,
  });

  @override
  State<_NextDoseCountdown> createState() => _NextDoseCountdownState();
}

class _NextDoseCountdownState extends State<_NextDoseCountdown> {
  Timer? _timer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final difference = widget.scheduledTime.difference(now);

    if (difference.isNegative) {
      setState(() {
        _countdownText = 'Time is due now';
      });
    } else {
      final totalSeconds = difference.inSeconds;
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final seconds = totalSeconds % 60;

      if (hours > 0) {
        setState(() {
          _countdownText = 'Next dose in $hours h ${minutes} m';
        });
      } else if (minutes > 0) {
        setState(() {
          _countdownText = 'Next dose in $minutes m ${seconds}s';
        });
      } else {
        setState(() {
          _countdownText = 'Next dose in ${seconds}s';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _countdownText,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
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
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
              color: widget.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                Icon(widget.icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
                  widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationCard extends ConsumerStatefulWidget {
  final Medication medication;
  final DateTime scheduledTime;
  final MedEventStatus? status;
  final bool isDark;

  const _MedicationCard({
    required this.medication,
    required this.scheduledTime,
    this.status,
    required this.isDark,
  });

  @override
  ConsumerState<_MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<_MedicationCard> {
  bool _isLoading = false;

  // Check if medication is recurring (no end date or frequency is daily)
  bool get _isRecurring => widget.medication.endDate == null || widget.medication.frequency.toLowerCase().contains('daily');

  Future<void> _markAsTaken() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final logsRepo = ref.read(logsRepositoryProvider);
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        widget.scheduledTime.hour,
        widget.scheduledTime.minute,
      );

      final log = MedLog(
        id: '',
        medicationId: widget.medication.id,
        timestamp: now,
        status: MedEventStatus.taken,
        scheduledDoseTime: scheduledDateTime,
      );

      await logsRepo.logMedicationEvent(log);

      // Invalidate providers to refresh the UI
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
    final localizations = MaterialLocalizations.of(context);
    final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    final timeOfDay = TimeOfDay.fromDateTime(widget.scheduledTime);
    final formattedTime = localizations.formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: use24Hour);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1F2937) : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.clock,
            size: 20,
            color: widget.isDark ? AppTheme.gray400 : AppTheme.gray600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.medication.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.isDark ? AppTheme.white : AppTheme.gray900,
                        ),
                      ),
                    ),
                    if (_isRecurring) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: widget.isDark ? AppTheme.teal500 : AppTheme.teal600,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.medication.dosage} • $formattedTime',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          if (widget.status != MedEventStatus.taken)
            TextButton(
              onPressed: _isLoading ? null : _markAsTaken,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.blue500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(100, 36),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Mark Taken',
                      style: TextStyle(fontSize: 12),
                    ),
            ),
          if (widget.status == MedEventStatus.taken)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Taken',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}