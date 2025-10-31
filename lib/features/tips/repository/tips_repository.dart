import 'package:cloud_firestore/cloud_firestore.dart';

class HealthTip {
  final String id;
  final String title;
  final String content;
  final String? category;
  final DateTime createdAt;

  HealthTip({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    required this.createdAt,
  });

  factory HealthTip.fromMap(String id, Map<String, dynamic> map) {
    return HealthTip(
      id: id,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class TipsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<HealthTip>> watchTips({int limit = 10}) {
    return _firestore
        .collection('healthTips')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => HealthTip.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<HealthTip>> getTips({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('healthTips')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => HealthTip.fromMap(doc.id, doc.data()))
        .toList();
  }
}

