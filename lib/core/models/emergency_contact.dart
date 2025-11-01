class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phone;
  final String? notes;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.notes,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? relationship,
    String? phone,
    String? notes,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'notes': notes,
    };
  }

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: (map['name'] as String?) ?? '',
      relationship: (map['relationship'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      notes: map['notes'] as String?,
    );
  }
}
