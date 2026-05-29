import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../admin/providers/admin_provider.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/services/onesignal_push_service.dart';

class ProfessorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OneSignalPushService _pushService = const OneSignalPushService();

  Future<DocumentReference> createExam(Map<String, dynamic> data) async {
    return await _firestore.collection('exams').add(data);
  }

  Future<void> updateExam(String examId, Map<String, dynamic> data) async {
    await _firestore.collection('exams').doc(examId).update(data);
  }

  Stream<bool> examHasResults(String examId) {
    return _firestore
        .collection('user_exam_results')
        .where('examId', isEqualTo: examId)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> deleteExam(ExamModel exam) async {
    if (exam.published || exam.isDone) {
      throw Exception('exam_delete_locked');
    }

    final resultSnapshot = await _firestore
        .collection('user_exam_results')
        .where('examId', isEqualTo: exam.id)
        .limit(1)
        .get();
    if (resultSnapshot.docs.isNotEmpty) {
      throw Exception('exam_delete_locked');
    }

    final questions = await _firestore
        .collection('exams')
        .doc(exam.id)
        .collection('questions')
        .get();
    final batch = _firestore.batch();
    for (final question in questions.docs) {
      batch.delete(question.reference);
    }
    batch.delete(_firestore.collection('exams').doc(exam.id));
    await batch.commit();
  }

  Future<void> deleteExamAsAdmin(ExamModel exam) async {
    final questions = await _firestore
        .collection('exams')
        .doc(exam.id)
        .collection('questions')
        .get();
    final results = await _firestore
        .collection('user_exam_results')
        .where('examId', isEqualTo: exam.id)
        .get();
    final alerts = await _firestore
        .collection('alerts')
        .where('examId', isEqualTo: exam.id)
        .get();

    final batch = _firestore.batch();
    for (final question in questions.docs) {
      batch.delete(question.reference);
    }
    for (final result in results.docs) {
      batch.delete(result.reference);
    }
    for (final alert in alerts.docs) {
      batch.delete(alert.reference);
    }
    batch.delete(_firestore.collection('exams').doc(exam.id));
    await batch.commit();
  }

  Future<void> sendExamToAdmin(ExamModel exam) async {
    if (exam.published || exam.isDone) {
      throw Exception('exam_send_locked');
    }

    final adminSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    final adminIds = adminSnapshot.docs.map((doc) => doc.id).toSet().toList();
    final now = Timestamp.fromDate(DateTime.now());

    final batch = _firestore.batch();
    batch.update(_firestore.collection('exams').doc(exam.id), {
      'published': false,
      'isActive': true,
      'status': 'sending',
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': _auth.currentUser?.uid ?? exam.teacherId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (adminIds.isNotEmpty) {
      final alertRef = _firestore.collection('alerts').doc();
      batch.set(alertRef, {
        'type': 'exam_sent_for_publish',
        'title': 'Ujian hein publish',
        'message':
            '${exam.title} (${exam.subject}) haruka ona husi mestre atu admin publish.',
        'examId': exam.id,
        'examTitle': exam.title,
        'subjectId': exam.subjectId,
        'subject': exam.subject,
        'recipientIds': adminIds,
        'readBy': <String>[],
        'scheduledAt': now,
        'examEndTime': Timestamp.fromDate(exam.endTime),
        'createdAt': now,
        'createdBy': _auth.currentUser?.uid ?? exam.teacherId,
      });
    }

    await batch.commit();

    try {
      await _pushService.sendToExternalIds(
        externalIds: adminIds,
        title: 'Ujian hein publish',
        message:
            '${exam.title} (${exam.subject}) haruka ona husi mestre atu admin publish.',
        type: 'exam_sent_for_publish',
        examId: exam.id,
      );
    } catch (_) {
      // The Firestore alert is the source of truth; push delivery is best effort.
    }
  }

  Future<void> publishExam({
    required ExamModel exam,
    required SubjectModel? subject,
    required String publisherId,
  }) async {
    if (exam.totalQuestions <= 0) {
      throw Exception('publish_requires_questions');
    }
    await _assertNoScheduleConflict(exam);

    final recipientIds = <String>{
      ...?subject?.teacherIds,
      ...?subject?.studentIds,
      if (exam.teacherId.isNotEmpty) exam.teacherId,
      if (exam.createdBy.isNotEmpty) exam.createdBy,
    }..removeWhere((id) => id.isEmpty);

    final now = Timestamp.fromDate(DateTime.now());
    final reminderAt = exam.startTime.subtract(
      Duration(minutes: exam.notificationLeadMinutes),
    );

    final batch = _firestore.batch();
    final examRef = _firestore.collection('exams').doc(exam.id);
    batch.update(examRef, {
      'published': true,
      'isActive': true,
      'status': 'published',
      'publishedAt': now,
      'publishedBy': publisherId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final pushJobs = <Future<void>>[];

    void addAlert({
      required String type,
      required String title,
      required String message,
      required DateTime scheduledAt,
    }) {
      final alertRef = _firestore.collection('alerts').doc();
      batch.set(alertRef, {
        'type': type,
        'title': title,
        'message': message,
        'examId': exam.id,
        'examTitle': exam.title,
        'subjectId': exam.subjectId,
        'subject': exam.subject,
        'recipientIds': recipientIds.toList(),
        'readBy': <String>[],
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'examEndTime': Timestamp.fromDate(exam.endTime),
        'createdAt': now,
        'createdBy': publisherId,
      });
      pushJobs.add(
        _pushService.sendToExternalIds(
          externalIds: recipientIds.toList(),
          title: title,
          message: message,
          type: type,
          examId: exam.id,
          sendAfter: scheduledAt,
        ),
      );
    }

    addAlert(
      type: 'exam_published',
      title: 'Ujian publish ona',
      message:
          '${exam.title} (${exam.subject}) sei hahu iha ${exam.startTime}.',
      scheduledAt: DateTime.now(),
    );
    addAlert(
      type: 'exam_reminder',
      title: 'Ujian atu hahu',
      message:
          '${exam.title} sei hahu iha ${exam.notificationLeadMinutes} minutu.',
      scheduledAt: reminderAt.isBefore(DateTime.now())
          ? DateTime.now()
          : reminderAt,
    );
    addAlert(
      type: 'exam_started',
      title: 'Ujian hahu ona',
      message: '${exam.title} (${exam.subject}) hahu ona agora.',
      scheduledAt: exam.startTime.isBefore(DateTime.now())
          ? DateTime.now()
          : exam.startTime,
    );

    await batch.commit();
    await Future.wait(
      pushJobs.map((job) async {
        try {
          await job;
        } catch (_) {
          // Publishing is already persisted. Push delivery must not show as a
          // failed publish when OneSignal rejects or delays a notification.
        }
      }),
    );
  }

  Future<void> _assertNoScheduleConflict(ExamModel exam) async {
    final snapshot = await _firestore.collection('exams').get();
    for (final doc in snapshot.docs) {
      if (doc.id == exam.id) continue;
      final other = ExamModel.fromMap(doc.data(), doc.id);
      if (!other.published || other.isDone) continue;
      final overlaps =
          exam.startTime.isBefore(other.endTime) &&
          exam.endTime.isAfter(other.startTime);
      if (overlaps) {
        throw Exception('exam_schedule_conflict');
      }
    }
  }

  Future<DocumentReference> addQuestion(
    String examId,
    Map<String, dynamic> data,
  ) async {
    final questionRef = await _firestore
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .add(data);
    await _firestore.collection('exams').doc(examId).update({
      'totalQuestions': FieldValue.increment(1),
      'published': false,
      'status': await _draftStatusForCurrentUser(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return questionRef;
  }

  Future<void> updateQuestion(
    String examId,
    String questionId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .doc(questionId)
        .update(data);
    await _firestore.collection('exams').doc(examId).update({
      'published': false,
      'status': await _draftStatusForCurrentUser(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuestion(String examId, String questionId) async {
    await _firestore
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .doc(questionId)
        .delete();
    await _firestore.collection('exams').doc(examId).update({
      'totalQuestions': FieldValue.increment(-1),
      'published': false,
      'status': await _draftStatusForCurrentUser(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _draftStatusForCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'draft';
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['role']?.toString() == 'admin' ? 'sending' : 'draft';
  }

  Stream<List<ExamModel>> getExamsByCreator(String uid) {
    return _firestore
        .collection('exams')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final exams = snap.docs
              .map((d) => ExamModel.fromMap(d.data(), d.id))
              .toList();
          exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return exams;
        });
  }

  Stream<List<ExamModel>> getAllExams() {
    return _firestore.collection('exams').snapshots().asyncMap((snap) async {
      final exams = snap.docs
          .map((d) => ExamModel.fromMap(d.data(), d.id))
          .toList();
      await _reconcileExpiredExams(exams);
      exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return exams;
    });
  }

  Future<void> _reconcileExpiredExams(List<ExamModel> exams) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final role = userDoc.data()?['role']?.toString() ?? '';
    if (role == 'student') {
      await _reconcileCurrentStudentExpiredExams(exams, uid);
      return;
    }
    if (role != 'admin' && role != 'teacher') return;

    final now = DateTime.now();
    for (final exam in exams) {
      if (!exam.published || !exam.isActive || !now.isAfter(exam.endTime)) {
        continue;
      }
      try {
        await _markExamDoneAndFillZeroResults(exam);
      } catch (_) {
        // Keep the stream alive if a user cannot finalize an unrelated exam.
      }
    }
  }

  Future<void> _markExamDoneAndFillZeroResults(ExamModel exam) async {
    DocumentSnapshot<Map<String, dynamic>>? subjectDoc;
    try {
      subjectDoc = exam.subjectId.isEmpty
          ? null
          : await _firestore.collection('subjects').doc(exam.subjectId).get();
    } catch (_) {
      return;
    }
    final studentIds = List<String>.from(
      (subjectDoc?.data()?['studentIds'] as List? ?? []).map(
        (studentId) => studentId.toString(),
      ),
    ).toSet();
    final validStudentIds = <String>{};
    for (final studentId in studentIds) {
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      if (userDoc.data()?['role']?.toString() == 'student') {
        validStudentIds.add(studentId);
      }
    }

    final existingResults = await _firestore
        .collection('user_exam_results')
        .where('examId', isEqualTo: exam.id)
        .get();
    final completedStudentIds = existingResults.docs
        .map((doc) => doc.data()['userId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final batch = _firestore.batch();
    for (final studentId in validStudentIds.difference(completedStudentIds)) {
      final resultRef = _firestore
          .collection('user_exam_results')
          .doc('${exam.id}_$studentId');
      batch.set(resultRef, {
        'userId': studentId,
        'studentId': studentId,
        'examId': exam.id,
        'examTitle': exam.title,
        'subjectId': exam.subjectId,
        'score': 0,
        'percentage': 0.0,
        'timeTaken': 0,
        'submittedAt': Timestamp.fromDate(exam.endTime),
        'autoGenerated': true,
      }, SetOptions(merge: true));
    }

    batch.update(_firestore.collection('exams').doc(exam.id), {
      'isActive': false,
      'status': 'done',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _deleteCurrentUserExamAlerts(exam);
  }

  Future<void> _reconcileCurrentStudentExpiredExams(
    List<ExamModel> exams,
    String uid,
  ) async {
    final now = DateTime.now();
    for (final exam in exams) {
      if (!exam.published || !now.isAfter(exam.endTime)) continue;
      DocumentSnapshot<Map<String, dynamic>>? subjectDoc;
      try {
        subjectDoc = exam.subjectId.isEmpty
            ? null
            : await _firestore.collection('subjects').doc(exam.subjectId).get();
      } catch (_) {
        continue;
      }
      final studentIds = List<String>.from(
        (subjectDoc?.data()?['studentIds'] as List? ?? []).map(
          (studentId) => studentId.toString(),
        ),
      );
      if (!studentIds.contains(uid)) continue;

      final submitted = await _firestore
          .collection('user_exam_results')
          .where('examId', isEqualTo: exam.id)
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();
      if (submitted.docs.isNotEmpty) continue;

      await _firestore
          .collection('user_exam_results')
          .doc('${exam.id}_$uid')
          .set({
            'userId': uid,
            'studentId': uid,
            'examId': exam.id,
            'examTitle': exam.title,
            'subjectId': exam.subjectId,
            'score': 0,
            'percentage': 0.0,
            'timeTaken': 0,
            'submittedAt': Timestamp.fromDate(exam.endTime),
            'autoGenerated': true,
          }, SetOptions(merge: true));
      await _deleteCurrentUserExamAlerts(exam);
    }
  }

  Future<void> _deleteCurrentUserExamAlerts(ExamModel exam) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final alerts = await _firestore
        .collection('alerts')
        .where('recipientIds', arrayContains: uid)
        .get();
    final batch = _firestore.batch();
    var hasDeletes = false;
    for (final alert in alerts.docs) {
      final data = alert.data();
      if (data['examId']?.toString() == exam.id) {
        batch.delete(alert.reference);
        hasDeletes = true;
      }
    }
    if (hasDeletes) {
      await batch.commit();
    }
  }
}

final professorRepositoryProvider = Provider<ProfessorRepository>(
  (ref) => ProfessorRepository(),
);

final myExamsProvider = StreamProvider.family<List<ExamModel>, String>((
  ref,
  uid,
) {
  return ref.watch(professorRepositoryProvider).getExamsByCreator(uid);
});

final allExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  return ref.watch(professorRepositoryProvider).getAllExams();
});

final subjectByIdProvider = Provider.family<SubjectModel?, String>((
  ref,
  subjectId,
) {
  final subjects = ref.watch(subjectsProvider).value ?? const <SubjectModel>[];
  return subjects.where((subject) => subject.id == subjectId).firstOrNull;
});

final examHasResultsProvider = StreamProvider.family<bool, String>((
  ref,
  examId,
) {
  return ref.watch(professorRepositoryProvider).examHasResults(examId);
});
