import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/user_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snap) {
      final users = snap.docs
          .map((d) => UserModel.fromMap(d.data(), d.id))
          .toList();
      users.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return users;
    });
  }

  Future<void> updateUserRole(UserModel user, String role) async {
    final newRole = UserModel.normalizeRole(role);
    if (newRole != 'student' && newRole != 'teacher') {
      throw 'role_admin_forbidden';
    }
    if (user.isAdmin) {
      throw 'role_admin_locked';
    }
    if (newRole == user.role) return;

    if (user.role.isNotEmpty && await isUserAssignedToAnySubject(user)) {
      throw 'role_subject_locked';
    }

    await _firestore.collection('users').doc(user.uid).update({
      'role': newRole,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectUser(UserModel user) async {
    if (user.isAdmin) {
      throw 'role_admin_locked';
    }
    if (await isUserAssignedToAnySubject(user)) {
      throw 'role_subject_locked';
    }
    if (!user.isActive && user.role.isEmpty) {
      throw 'delete_rejected_only';
    }

    await _firestore.collection('users').doc(user.uid).update({
      'role': '',
      'isActive': false,
      'selectedSubjectId': '',
      'rejectedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRejectedUser(UserModel user) async {
    if (user.isAdmin) {
      throw 'role_admin_locked';
    }
    if (user.isActive || user.role.isNotEmpty) {
      throw 'delete_rejected_only';
    }

    await _firestore.collection('users').doc(user.uid).delete();
  }

  Future<bool> isUserAssignedToAnySubject(UserModel user) async {
    final teacherSubjects = await _firestore
        .collection('subjects')
        .where('teacherIds', arrayContains: user.uid)
        .limit(1)
        .get();
    if (teacherSubjects.docs.isNotEmpty) return true;

    final studentSubjects = await _firestore
        .collection('subjects')
        .where('studentIds', arrayContains: user.uid)
        .limit(1)
        .get();
    return studentSubjects.docs.isNotEmpty;
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

  Future<void> removeStudentFromSubject({
    required String subjectId,
    required String studentId,
    required List<String> remainingStudentIds,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('subjects').doc(subjectId), {
      'studentIds': remainingStudentIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final userRef = _firestore.collection('users').doc(studentId);
    final userDoc = await userRef.get();
    if (userDoc.data()?['selectedSubjectId']?.toString() == subjectId) {
      batch.update(userRef, {
        'selectedSubjectId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> deleteSubject(String subjectId) async {
    final subjectRef = _firestore.collection('subjects').doc(subjectId);
    final subjectDoc = await subjectRef.get();
    final data = subjectDoc.data();
    if (data == null) return;

    final teacherIds = (data['teacherIds'] as List? ?? const [])
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty);
    final studentIds = (data['studentIds'] as List? ?? const [])
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty);
    if (teacherIds.isNotEmpty || studentIds.isNotEmpty) {
      throw 'subject_delete_locked';
    }

    await subjectRef.delete();
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
      return ref
          .watch(adminRepositoryProvider)
          .getSubjectsForTeacher(teacherId);
    });

final studentSubjectsProvider =
    StreamProvider.family<List<SubjectModel>, String>((ref, studentId) {
      return ref
          .watch(adminRepositoryProvider)
          .getSubjectsForStudent(studentId);
    });
