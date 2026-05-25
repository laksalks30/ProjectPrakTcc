// ============ FILE: mobile_app/lib/models/user.dart ============

int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': createdAt,
      };

  bool get isAdmin => role == 'admin';
}
