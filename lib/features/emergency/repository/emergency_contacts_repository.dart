import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/emergency_contact.dart';

class EmergencyContactsRepository {
  EmergencyContactsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> _collection() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('emergencyContacts');
  }

  Stream<List<EmergencyContact>> watchContacts() {
    if (_userId.isEmpty) {
      return Stream.value(const []);
    }

    try {
      return _collection()
          .snapshots()
          .map((snapshot) {
            try {
              final contacts = snapshot.docs
                  .map((doc) {
                    try {
                      final data = doc.data();
                      if (data.isEmpty) return null;
                      return EmergencyContact.fromMap(doc.id, data);
                    } catch (e) {
                      debugPrint('Error parsing contact ${doc.id}: $e');
                      return null;
                    }
                  })
                  .whereType<EmergencyContact>()
                  .toList();
              // Sort locally instead of using orderBy to avoid index requirement
              contacts.sort((a, b) => a.name.compareTo(b.name));
              return contacts;
            } catch (e) {
              debugPrint('Error processing contacts snapshot: $e');
              return <EmergencyContact>[];
            }
          })
          .handleError(
            (error) {
              debugPrint('Error in watchContacts stream: $error');
              // Return empty list on error instead of crashing
            },
            test: (error) => true, // Catch all errors
          );
    } catch (e) {
      debugPrint('Error creating watchContacts stream: $e');
      return Stream.value(<EmergencyContact>[]);
    }
  }

  Future<List<EmergencyContact>> fetchContacts() async {
    if (_userId.isEmpty) return [];

    final snapshot = await _collection().get();
    final contacts = snapshot.docs
        .map((doc) => EmergencyContact.fromMap(doc.id, doc.data()))
        .toList();
    contacts.sort((a, b) => a.name.compareTo(b.name));
    return contacts;
  }

  Future<String> addContact(EmergencyContact contact) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final docRef = await _collection().add(contact.toMap());
    return docRef.id;
  }

  Future<void> updateContact(String id, EmergencyContact contact) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _collection().doc(id).update(contact.toMap());
  }

  Future<void> deleteContact(String id) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _collection().doc(id).delete();
  }
}
