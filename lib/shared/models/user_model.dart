import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String school;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.school,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'school': school,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedDate = (map['createdAt'] as Timestamp).toDate();
      } else {
        parsedDate = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return UserModel(
      uid: id,
      name: map['name'] ?? 'Naran la hatene',
      email: map['email'] ?? '',
      school: map['school'] ?? 'Eskola la hatene',
      role: map['role'] ?? 'student',
      createdAt: parsedDate,
    );
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? school,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      school: school ?? this.school,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
