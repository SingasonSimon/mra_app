import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../logs/providers/logs_providers.dart';
import '../../../core/models/med_log.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final logsAsync = ref.watch(logsStreamProvider(now));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: logsAsync.when(
        data: (logs) {
          final achievements = _calculateAchievements(logs);
          final unlockedCount = achievements.where((a) => a.unlocked).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Progress',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '$unlockedCount of ${achievements.length} unlocked',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your Achievements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...achievements.map((achievement) => _AchievementCard(achievement: achievement)),
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
      ),
    );
  }

  List<Achievement> _calculateAchievements(List<MedLog> logs) {
    final taken = logs.where((log) => log.status == MedEventStatus.taken).length;
    final now = DateTime.now();
    
    // Calculate streak
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        final checkDate = DateTime(date.year, date.month, date.day);
        return logDate.isAtSameMomentAs(checkDate);
      }).toList();

      if (dayLogs.isEmpty) break;
      final dayTaken = dayLogs.where((log) => log.status == MedEventStatus.taken).length;
      if (dayTaken > 0) {
        streak++;
      } else {
        break;
      }
    }

    return [
      Achievement(
        id: 'first_dose',
        title: 'First Steps',
        description: 'Log your first medication dose',
        icon: '🎯',
        unlocked: taken >= 1,
      ),
      Achievement(
        id: 'week_warrior',
        title: 'Week Warrior',
        description: 'Take medications for 7 consecutive days',
        icon: '⚔️',
        unlocked: streak >= 7,
      ),
      Achievement(
        id: 'month_master',
        title: 'Month Master',
        description: 'Maintain a 30-day streak',
        icon: '👑',
        unlocked: streak >= 30,
      ),
      Achievement(
        id: 'perfect_week',
        title: 'Perfect Week',
        description: '100% adherence for 7 days',
        icon: '💯',
        unlocked: _hasPerfectWeek(logs),
      ),
      Achievement(
        id: 'century',
        title: 'Century Club',
        description: 'Log 100 medication doses',
        icon: '💊',
        unlocked: taken >= 100,
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Take morning medications on time for 7 days',
        icon: '🌅',
        unlocked: _hasEarlyBird(logs),
      ),
    ];
  }

  bool _hasPerfectWeek(List<MedLog> logs) {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        final checkDate = DateTime(date.year, date.month, date.day);
        return logDate.isAtSameMomentAs(checkDate);
      }).toList();

      if (dayLogs.isEmpty) return false;
      final allTaken = dayLogs.every((log) => log.status == MedEventStatus.taken);
      if (!allTaken) return false;
    }
    return true;
  }

  bool _hasEarlyBird(List<MedLog> logs) {
    final now = DateTime.now();
    int earlyBirdDays = 0;
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayLogs = logs.where((log) {
        final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
        final checkDate = DateTime(date.year, date.month, date.day);
        return logDate.isAtSameMomentAs(checkDate) && log.timestamp.hour < 12;
      }).toList();

      final morningTaken = dayLogs.where((log) => log.status == MedEventStatus.taken).length;
      if (morningTaken > 0) earlyBirdDays++;
    }
    return earlyBirdDays >= 7;
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: achievement.unlocked ? null : Colors.grey.shade200,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: achievement.unlocked
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade300,
          radius: 28,
          child: Text(
            achievement.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: achievement.unlocked ? null : Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            color: achievement.unlocked ? null : Colors.grey.shade600,
          ),
        ),
        trailing: achievement.unlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}

