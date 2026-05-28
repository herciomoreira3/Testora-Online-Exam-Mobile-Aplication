import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.teacherIds,
    required this.studentIds,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String description;
  final List<String> teacherIds;
  final List<String> studentIds;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'teacherIds': teacherIds,
      'studentIds': studentIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else {
      parsedCreatedAt =
          DateTime.tryParse(rawCreatedAt?.toString() ?? '') ?? DateTime.now();
    }

    List<String> readIds(dynamic value) {
      if (value is List) return value.map((item) => item.toString()).toList();
      return const [];
    }

    return SubjectModel(
      id: id,
      name: map['name'] ?? 'Materia',
      description: map['description'] ?? '',
      teacherIds: readIds(map['teacherIds']),
      studentIds: readIds(map['studentIds']),
      isActive: map['isActive'] ?? true,
      createdAt: parsedCreatedAt,
    );
  }
}
