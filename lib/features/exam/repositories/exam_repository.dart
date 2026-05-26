import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../../../shared/models/result_model.dart';

class ExamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream active exams from Firestore
  Stream<List<ExamModel>> getActiveExams() {
    return _firestore
        .collection('exams')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ExamModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Fetch all questions under exams/{examId}/questions subcollection
  Future<List<QuestionModel>> getQuestionsForExam(String examId) async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .doc(examId)
          .collection('questions')
          .get();

      return snapshot.docs.map((doc) {
        return QuestionModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw 'Akontese sala bainhira load pergunta sira.';
    }
  }

  // Submit test scoring results to user_exam_results collection
  Future<void> submitExamResult(ResultModel result) async {
    try {
      await _firestore.collection('user_exam_results').add(result.toMap());
    } catch (e) {
      throw 'Akontese sala bainhira entrega teste.';
    }
  }

  // Stream completed exam results for a specific student for history rendering
  Stream<List<ResultModel>> getStudentExamResults(String userId) {
    return _firestore
        .collection('user_exam_results')
        .where('userId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ResultModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
