import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/medication_repository.dart';
import '../../../core/models/medication.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

final medicationsStreamProvider = StreamProvider<List<Medication>>((ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.watchMedications();
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return await repository.getMedications();
});

