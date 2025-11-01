import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/emergency_contact.dart';
import '../repository/emergency_contacts_repository.dart';

final emergencyContactsRepositoryProvider =
    Provider<EmergencyContactsRepository>(
      (ref) => EmergencyContactsRepository(),
    );

final emergencyContactsStreamProvider = StreamProvider<List<EmergencyContact>>((
  ref,
) {
  final repository = ref.watch(emergencyContactsRepositoryProvider);
  return repository.watchContacts();
});
