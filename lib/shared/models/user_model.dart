import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String school;
  final String role;
  final String language;
  final String photoUrl;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.school,
    required this.role,
    this.language = 'tet',
    this.photoUrl = '',
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  static String normalizeRole(String? value) {
    final role = (value ?? '').toLowerCase().trim();
    if (role.isEmpty) return '';
    if (role == 'admin') return 'admin';
    if (role == 'teacher' ||
        role == 'guru' ||
        role == 'professor' ||
        role == 'professores' ||
        role.contains('prof')) {
      return 'teacher';
    }
    if (role == 'student' || role == 'estudante' || role == 'murid') {
      return 'student';
    }
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'school': school,
      'role': role,
      'language': language,
      'photoUrl': photoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else {
        parsedDate =
            DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: id,
      name: map['name'] ?? 'Naran la hatene',
      email: map['email'] ?? '',
      school: map['school'] ?? 'Eskola la hatene',
      role: normalizeRole(map['role'] as String?),
      language: map['language'] ?? 'tet',
      photoUrl: map['photoUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: parsedDate,
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? school,
    String? role,
    String? language,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      school: school ?? this.school,
      role: role ?? this.role,
      language: language ?? this.language,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
