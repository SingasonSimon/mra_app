import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/appointment.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Stream<List<Appointment>> watchAppointments() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appointment.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<Appointment>> getAppointments() async {
    if (_userId.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .orderBy('dateTime', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Appointment>> getUpcomingAppointments({int daysAhead = 30}) async {
    if (_userId.isEmpty) return [];

    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: now.millisecondsSinceEpoch)
        .where('dateTime', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch)
        .orderBy('dateTime', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => Appointment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Appointment?> getAppointment(String id) async {
    if (_userId.isEmpty) return null;

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return Appointment.fromMap(doc.id, doc.data()!);
  }

  Future<String> addAppointment(Appointment appointment) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final docRef = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .add(appointment.toMap());

    return docRef.id;
  }

  Future<void> updateAppointment(String id, Appointment appointment) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .doc(id)
        .update(appointment.toMap());
  }

  Future<void> deleteAppointment(String id) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('appointments')
        .doc(id)
        .delete();
  }
}

