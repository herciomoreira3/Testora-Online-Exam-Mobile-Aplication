import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/providers/admin_provider.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/services/onesignal_push_service.dart';

class ProfessorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    if (exam.published || !DateTime.now().isBefore(exam.startTime)) {
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

  Future<void> publishExam({
    required ExamModel exam,
    required SubjectModel? subject,
    required String publisherId,
  }) async {
    if (exam.totalQuestions <= 0) {
      throw Exception('publish_requires_questions');
    }

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

    await batch.commit();
    await Future.wait(pushJobs);
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ExamModel>> getExamsByCreator(String uid) {
    return _firestore
        .collection('exams')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final exams =
              snap.docs.map((d) => ExamModel.fromMap(d.data(), d.id)).toList();
          exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return exams;
        });
  }

  Stream<List<ExamModel>> getAllExams() {
    return _firestore.collection('exams').snapshots().map((snap) {
      final exams =
          snap.docs.map((d) => ExamModel.fromMap(d.data(), d.id)).toList();
      exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return exams;
    });
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
