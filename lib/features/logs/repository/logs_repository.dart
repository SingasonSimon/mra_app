import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/med_log.dart';

class LogsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> logMedicationEvent(MedLog log) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medLogs')
        .add(log.toMap());
  }

  Stream<List<MedLog>> watchLogs({DateTime? startDate, DateTime? endDate}) {
    if (_userId.isEmpty) return Stream.value([]);

    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('medLogs')
        .orderBy('timestamp', descending: true)
        .limit(500); // Increased limit for history views

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <MedLog>[];
      }
      
      var logs = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return null;
          return MedLog.fromMap(doc.id, data);
        } catch (e) {
          debugPrint('Error parsing log document ${doc.id}: $e');
          return null;
        }
      }).whereType<MedLog>().toList();
      
      // Filter by date range in memory if needed
      if (startDate != null) {
        logs = logs.where((log) => log.timestamp.isAfter(startDate.subtract(const Duration(seconds: 1)))).toList();
      }
      if (endDate != null) {
        logs = logs.where((log) => log.timestamp.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }
      
      return logs;
    });
  }

  Future<List<MedLog>> getLogsForMedication(String medicationId, {int? limit}) async {
    if (_userId.isEmpty) return [];

    // Use where only, then sort in memory to avoid needing composite index
    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('medLogs')
        .where('medicationId', isEqualTo: medicationId);

    final snapshot = await query.get();
    var logs = snapshot.docs
        .map((doc) => MedLog.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    
    // Sort by timestamp descending in memory
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null) {
      logs = logs.take(limit).toList();
    }
    
    return logs;
  }

  Future<Map<String, dynamic>> getAdherenceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId.isEmpty) return {'taken': 0, 'total': 0, 'percentage': 0.0};

    final now = endDate ?? DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 7));

    final logs = await watchLogs(startDate: start, endDate: now).first;
    final taken = logs.where((log) => log.status == MedEventStatus.taken).length;
    final total = logs.length;

    return {
      'taken': taken,
      'total': total,
      'percentage': total > 0 ? (taken / total * 100) : 0.0,
    };
  }
}

