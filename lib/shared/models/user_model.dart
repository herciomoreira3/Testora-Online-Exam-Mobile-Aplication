import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String school;
  final String role;
  final String language;
  final String photoUrl;
  final bool darkMode;
  final String selectedSubjectId;
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
    this.darkMode = false,
    this.selectedSubjectId = '',
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  static String normalizeRole(String? value) {
    final role = (value ?? '').toLowerCase().trim();
    if (role.isEmpty) return '';
    if (role == 'admin' || role == 'administrator' || role == 'administrador') {
      return 'admin';
    }
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
      'darkMode': darkMode,
      'selectedSubjectId': selectedSubjectId,
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
      darkMode: map['darkMode'] == true,
      selectedSubjectId: map['selectedSubjectId']?.toString() ?? '',
      isActive: _readBool(map['isActive'], fallback: true),
      createdAt: parsedDate,
    );
  }

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return fallback;
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? school,
    String? role,
    String? language,
    String? photoUrl,
    bool? darkMode,
    String? selectedSubjectId,
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
      darkMode: darkMode ?? this.darkMode,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
