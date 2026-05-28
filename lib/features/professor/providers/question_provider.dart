import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/question_model.dart';

class QuestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<QuestionModel>> getQuestions(String examId) {
    return _firestore
        .collection('exams')
        .doc(examId)
        .collection('questions')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuestionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(),
);

final examQuestionsProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, examId) {
      return ref.watch(questionRepositoryProvider).getQuestions(examId);
    });
