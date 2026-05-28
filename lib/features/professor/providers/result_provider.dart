import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/result_model.dart';
import '../../exam/repositories/exam_repository.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(),
);

// Stream of results for a given exam id
final examResultsProvider = StreamProvider.family<List<ResultModel>, String>((
  ref,
  examId,
) {
  return ref.watch(examRepositoryProvider).getResultsForExam(examId);
});
