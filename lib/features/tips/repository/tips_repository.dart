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

  Stream<List<HealthTip>> watchTips({
    int limit = 10,
    String? category,
    List<String>? userConditions,
  }) {
    Query query = _firestore
        .collection('healthTips')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      var tips = snapshot.docs
          .map((doc) => HealthTip.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      // Prioritize tips relevant to user conditions
      if (userConditions != null && userConditions.isNotEmpty) {
        tips.sort((a, b) {
          final aRelevant = a.category != null && userConditions.contains(a.category!.toLowerCase());
          final bRelevant = b.category != null && userConditions.contains(b.category!.toLowerCase());
          if (aRelevant && !bRelevant) return -1;
          if (!aRelevant && bRelevant) return 1;
          return 0;
        });
      }

      return tips;
    });
  }

  Future<List<HealthTip>> getTips({
    int limit = 10,
    String? category,
    List<String>? userConditions,
  }) async {
    Query query = _firestore
        .collection('healthTips')
        .orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.limit(limit).get();

    var tips = snapshot.docs
        .map((doc) => HealthTip.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Prioritize tips relevant to user conditions
    if (userConditions != null && userConditions.isNotEmpty) {
      tips.sort((a, b) {
        final aRelevant = a.category != null && userConditions.contains(a.category!.toLowerCase());
        final bRelevant = b.category != null && userConditions.contains(b.category!.toLowerCase());
        if (aRelevant && !bRelevant) return -1;
        if (!aRelevant && bRelevant) return 1;
        return 0;
      });
    }

    return tips;
  }
}

