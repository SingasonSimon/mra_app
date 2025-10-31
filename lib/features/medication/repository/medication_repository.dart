import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/medication.dart';

class MedicationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Stream<List<Medication>> watchMedications() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Medication.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<Medication>> getMedications() async {
    if (_userId.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .get();

    return snapshot.docs
        .map((doc) => Medication.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Medication?> getMedication(String id) async {
    if (_userId.isEmpty) return null;

    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .doc(id)
        .get();

    if (!doc.exists) return null;
    return Medication.fromMap(doc.id, doc.data()!);
  }

  Future<String> addMedication(Medication medication) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final docRef = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .add(medication.toMap());

    return docRef.id;
  }

  Future<void> updateMedication(String id, Medication medication) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .doc(id)
        .update(medication.toMap());
  }

  Future<void> deleteMedication(String id) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .doc(id)
        .delete();
  }
}

