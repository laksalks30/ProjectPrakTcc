// ============ FILE: mobile_app/lib/models/patient.dart ============

/// Helper: API bisa mengembalikan id sebagai String atau int
int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? _toIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}

class Patient {
  final int id;
  final int? userId;
  final String name;
  final String? birthDate;
  final String gender;
  final String? address;
  final String? bloodType;
  final String? photoUrl;
  final String? medicalNotes;
  final int? caregiverId;
  final String? createdAt;

  Patient({
    required this.id,
    this.userId,
    required this.name,
    this.birthDate,
    required this.gender,
    this.address,
    this.bloodType,
    this.photoUrl,
    this.medicalNotes,
    this.caregiverId,
    this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: _toInt(json['id']),
      userId: _toIntNullable(json['user_id']),
      name: json['name'] ?? '',
      birthDate: json['birth_date'],
      gender: json['gender'] ?? 'male',
      address: json['address'],
      bloodType: json['blood_type'],
      photoUrl: json['photo_url'],
      medicalNotes: json['medical_notes'],
      caregiverId: _toIntNullable(json['caregiver_id']),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'birth_date': birthDate,
        'gender': gender,
        'address': address,
        'blood_type': bloodType,
        'photo_url': photoUrl,
        'medical_notes': medicalNotes,
        'caregiver_id': caregiverId,
      };

  String get genderLabel => gender == 'male' ? 'Laki-laki' : 'Perempuan';
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
