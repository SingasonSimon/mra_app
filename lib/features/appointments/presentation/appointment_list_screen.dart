import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/appointment_providers.dart';
import '../../../core/models/appointment.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  String _filter = 'all'; // 'all', 'upcoming', 'past'

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _filter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'all');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Upcoming'),
                    selected: _filter == 'upcoming',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'upcoming');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Past'),
                    selected: _filter == 'past',
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = 'past');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final now = DateTime.now();
          List<Appointment> filteredAppointments;

          if (_filter == 'upcoming') {
            filteredAppointments = appointments.where((a) => a.dateTime.isAfter(now)).toList();
          } else if (_filter == 'past') {
            filteredAppointments = appointments.where((a) => a.dateTime.isBefore(now)).toList();
          } else {
            filteredAppointments = appointments;
          }

          if (filteredAppointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 'all' 
                        ? 'No appointments yet'
                        : _filter == 'upcoming'
                            ? 'No upcoming appointments'
                            : 'No past appointments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first appointment',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAppointments.length,
            itemBuilder: (context, index) {
              final appointment = filteredAppointments[index];
              final isUpcoming = appointment.isUpcoming;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUpcoming 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.event,
                      color: isUpcoming 
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(appointment.doctorName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.reason),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            appointment.formattedDate,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            appointment.formattedTime,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (appointment.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                appointment.location!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'view') {
                        context.push('/appointments/${appointment.id}');
                      } else if (value == 'edit') {
                        context.push(
                          '/appointments/add',
                          extra: appointment,
                        );
                      } else if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Appointment'),
                            content: Text('Are you sure you want to delete the appointment with ${appointment.doctorName}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          try {
                            final repository = ref.read(appointmentRepositoryProvider);
                            await repository.deleteAppointment(appointment.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Appointment deleted')),
                              );
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
                    },
                  ),
                  onTap: () {
                    context.push('/appointments/${appointment.id}');
                  },
                ),
              );
            },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/appointments/add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Appointment'),
      ),
    );
  }
}

