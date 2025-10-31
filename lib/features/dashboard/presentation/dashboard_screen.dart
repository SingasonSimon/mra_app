import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../medication/providers/medication_providers.dart';
import '../../../core/models/medication.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => context.push('/tips'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final repository = ref.read(authRepositoryProvider);
              await repository.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome${profileAsync.value?.name != null ? ', ${profileAsync.value!.name}' : ''}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Medications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => context.push('/medications'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final medicationsAsync = ref.watch(medicationsStreamProvider);
                  return medicationsAsync.when(
                    data: (medications) {
                      if (medications.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medication,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No medications scheduled',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first medication to get started',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final now = DateTime.now();
                      final upcomingMeds = medications
                          .where((med) {
                            if (med.endDate != null && med.endDate!.isBefore(now)) {
                              return false;
                            }
                            return med.startDate.isBefore(now) || med.startDate.isAtSameMomentAs(now);
                          })
                          .toList();

                      if (upcomingMeds.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No upcoming medications today',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: upcomingMeds.take(3).map((med) {
                          final nextTime = _getNextDoseTime(med);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.medication,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(med.name),
                              subtitle: Text('${med.dosage} • Next: $nextTime'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Navigate to medication detail
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (error, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error loading medications: $error'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/medications/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  String _getNextDoseTime(Medication medication) {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    for (final time in medication.timesPerDay) {
      final timeMinutes = time.hour * 60 + time.minute;
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;

      if (timeMinutes > currentMinutes) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    }

    // If all times passed, return first time tomorrow
    if (medication.timesPerDay.isNotEmpty) {
      final firstTime = medication.timesPerDay.first;
      return '${firstTime.hour.toString().padLeft(2, '0')}:${firstTime.minute.toString().padLeft(2, '0')} (tomorrow)';
    }

    return 'No times scheduled';
  }
}

