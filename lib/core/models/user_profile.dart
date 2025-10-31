class UserProfile {
  final String uid;
  final String name;
  final int? age;
  final String? gender;
  final List<String> conditions;
  final String? emergencyContact;
  final List<String> caregiverIds;

  UserProfile({
    required this.uid,
    required this.name,
    this.age,
    this.gender,
    this.conditions = const [],
    this.emergencyContact,
    this.caregiverIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'conditions': conditions,
      'emergencyContact': emergencyContact,
      'caregiverIds': caregiverIds,
    };
  }

  static UserProfile fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      conditions: (map['conditions'] as List<dynamic>? ?? const []).cast<String>(),
      emergencyContact: map['emergencyContact'] as String?,
      caregiverIds: (map['caregiverIds'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}


