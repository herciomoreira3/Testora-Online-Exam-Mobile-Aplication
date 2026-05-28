import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/user_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snap) {
          final users =
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
          users.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return users;
        });
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }

  Stream<List<SubjectModel>> getSubjects() {
    return _firestore.collection('subjects').snapshots().map((snap) {
      final subjects = snap.docs
          .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
          .toList();
      subjects.sort((a, b) => a.name.compareTo(b.name));
      return subjects;
    });
  }

  Stream<List<SubjectModel>> getSubjectsForTeacher(String teacherId) {
    return _firestore
        .collection('subjects')
        .where('teacherIds', arrayContains: teacherId)
        .snapshots()
        .map((snap) {
          final subjects = snap.docs
              .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
              .toList();
          subjects.sort((a, b) => a.name.compareTo(b.name));
          return subjects;
        });
  }

  Stream<List<SubjectModel>> getSubjectsForStudent(String studentId) {
    return _firestore
        .collection('subjects')
        .where('studentIds', arrayContains: studentId)
        .snapshots()
        .map((snap) {
          final subjects = snap.docs
              .map((doc) => SubjectModel.fromMap(doc.data(), doc.id))
              .toList();
          subjects.sort((a, b) => a.name.compareTo(b.name));
          return subjects;
        });
  }

  Future<void> saveSubject({
    String? id,
    required String name,
    required String description,
    bool isActive = true,
  }) async {
    final data = {
      'name': name,
      'description': description,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null || id.isEmpty) {
      await _firestore.collection('subjects').add({
        ...data,
        'teacherIds': <String>[],
        'studentIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _firestore.collection('subjects').doc(id).update(data);
  }

  Future<void> assignTeachersToSubject(
    String subjectId,
    List<String> teacherIds,
  ) async {
    await _firestore.collection('subjects').doc(subjectId).update({
      'teacherIds': teacherIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignStudentsToSubject(
    String subjectId,
    List<String> studentIds,
  ) async {
    await _firestore.collection('subjects').doc(subjectId).update({
      'studentIds': studentIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubject(String subjectId) async {
    await _firestore.collection('subjects').doc(subjectId).delete();
  }
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(),
);

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

final subjectsProvider = StreamProvider<List<SubjectModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getSubjects();
});

final teacherSubjectsProvider =
    StreamProvider.family<List<SubjectModel>, String>((ref, teacherId) {
  return ref.watch(adminRepositoryProvider).getSubjectsForTeacher(teacherId);
});

final studentSubjectsProvider =
    StreamProvider.family<List<SubjectModel>, String>((ref, studentId) {
  return ref.watch(adminRepositoryProvider).getSubjectsForStudent(studentId);
});
