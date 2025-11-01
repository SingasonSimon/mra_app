import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/appointment_repository.dart';
import '../../../core/models/appointment.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository();
});

final appointmentsStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.watchAppointments();
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAppointments();
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getUpcomingAppointments(daysAhead: 30);
});

final appointmentProvider = FutureProvider.family<Appointment?, String>((ref, id) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return await repository.getAppointment(id);
});

