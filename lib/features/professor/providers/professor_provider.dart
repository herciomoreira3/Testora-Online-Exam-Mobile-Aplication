import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exam/repositories/exam_repository.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../../../shared/models/result_model.dart';

// Repository provider (already exists in exam feature)
final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(),
);

// Stream of active exams for professor dashboard
final professorExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  return ref.watch(examRepositoryProvider).getActiveExams();
});

// Create a new exam (returns created ExamModel with generated ID)
class CreateExamParams {
  final String title;
  final String description;
  final int duration;
  final String category;
  final String createdBy;
  CreateExamParams({
    required this.title,
    required this.description,
    required this.duration,
    required this.category,
    required this.createdBy,
  });
}

final createExamProvider = FutureProvider.family<void, CreateExamParams>((
  ref,
  params,
) async {
  // Direct Firestore access to add exam with custom fields
  await FirebaseFirestore.instance.collection('exams').add({
    'title': params.title,
    'description': params.description,
    'duration': params.duration,
    'totalQuestions': 0,
    'category': params.category,
    'isActive': true,
    'createdBy': params.createdBy,
    'createdAt': DateTime.now(),
  });
  // No return needed
});

// Fetch questions for a specific exam
final examQuestionsProvider =
    FutureProvider.family<List<QuestionModel>, String>((ref, examId) async {
      return await ref
          .watch(examRepositoryProvider)
          .getQuestionsForExam(examId);
    });

// Submit exam result (used by professor view results screen)
final submitResultProvider = FutureProvider.family<void, ResultModel>((
  ref,
  result,
) async {
  await ref.watch(examRepositoryProvider).submitExamResult(result);
});
