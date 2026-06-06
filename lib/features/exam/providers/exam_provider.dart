import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/question_model.dart';
import '../../../shared/models/result_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/exam_repository.dart';
import 'timer_provider.dart';

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ExamRepository(),
);

final examClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final activeExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  return ref.watch(examRepositoryProvider).getActiveExams();
});

final publishedExamsProvider = StreamProvider<List<ExamModel>>((ref) {
  return ref.watch(examRepositoryProvider).getPublishedExams();
});

class ExamSessionState {
  final ExamModel exam;
  final List<QuestionModel> questions;
  final int currentIndex;
  final Map<String, int> answers; // questionId -> selectedOptionIndex
  final bool isSubmitting;
  final int timerStartSeconds;

  ExamSessionState({
    required this.exam,
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    this.isSubmitting = false,
    this.timerStartSeconds = 0,
  });

  ExamSessionState copyWith({
    ExamModel? exam,
    List<QuestionModel>? questions,
    int? currentIndex,
    Map<String, int>? answers,
    bool? isSubmitting,
    int? timerStartSeconds,
  }) {
    return ExamSessionState(
      exam: exam ?? this.exam,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      timerStartSeconds: timerStartSeconds ?? this.timerStartSeconds,
    );
  }
}

class ExamSessionNotifier extends Notifier<ExamSessionState?> {
  @override
  ExamSessionState? build() {
    return null;
  }

  // Start exam session
  Future<void> startSession(ExamModel exam, void Function() onTimeUp) async {
    state = ExamSessionState(
      exam: exam,
      questions: [],
      isSubmitting: true, // Show loading while fetching questions
    );

    try {
      final questions = await ref
          .read(examRepositoryProvider)
          .getQuestionsForExam(exam.id);
      final orderedQuestions = [...questions];
      if (exam.shuffleQuestions) {
        orderedQuestions.shuffle();
      }

      final timerStartSeconds = _initialTimerSeconds(exam);
      state = ExamSessionState(
        exam: exam,
        questions: orderedQuestions,
        currentIndex: 0,
        answers: {},
        isSubmitting: false,
        timerStartSeconds: timerStartSeconds,
      );

      ref
          .read(examTimerProvider.notifier)
          .startSeconds(timerStartSeconds, onTimeUp);
    } catch (e) {
      state = null;
      rethrow;
    }
  }

  int _initialTimerSeconds(ExamModel exam) {
    final durationSeconds = exam.duration * 60;
    final windowSeconds = exam.endTime.difference(DateTime.now()).inSeconds;
    if (windowSeconds <= 0) return 0;
    if (windowSeconds > durationSeconds) return durationSeconds;
    return windowSeconds;
  }

  // Answer selection
  void selectOption(String questionId, int optionIndex) {
    if (state == null) return;
    final updatedAnswers = Map<String, int>.from(state!.answers);
    updatedAnswers[questionId] = optionIndex;
    state = state!.copyWith(answers: updatedAnswers);
  }

  // Go to next question
  void nextQuestion() {
    if (state == null || state!.currentIndex >= state!.questions.length - 1) {
      return;
    }
    state = state!.copyWith(currentIndex: state!.currentIndex + 1);
  }

  // Go to previous question
  void previousQuestion() {
    if (state == null || state!.currentIndex <= 0) {
      return;
    }
    state = state!.copyWith(currentIndex: state!.currentIndex - 1);
  }

  // Calculate results and submit to Firestore
  Future<ResultModel> submit() async {
    if (state == null) throw 'La iha teste ativu.';

    final currentSession = state!;
    state = currentSession.copyWith(isSubmitting: true);

    try {
      final userId = ref.read(authRepositoryProvider).currentUid;
      if (userId == null) throw 'Uzuriário la autentikadu.';

      int correctCount = 0;
      for (var question in currentSession.questions) {
        final userAnswer = currentSession.answers[question.id];
        if (userAnswer != null && userAnswer == question.correctAnswerIndex) {
          correctCount++;
        }
      }

      final percentage = currentSession.questions.isNotEmpty
          ? (correctCount / currentSession.questions.length) * 100.0
          : 0.0;

      final remainingSeconds = ref.read(examTimerProvider);
      final timeTaken =
          (currentSession.timerStartSeconds - remainingSeconds)
              .clamp(0, currentSession.timerStartSeconds)
              .toInt();

      // Stop the timer
      ref.read(examTimerProvider.notifier).stop();

      final result = ResultModel(
        id: '',
        userId: userId,
        examId: currentSession.exam.id,
        examTitle: currentSession.exam.title,
        subjectId: currentSession.exam.subjectId,
        score: correctCount,
        percentage: percentage,
        timeTaken: timeTaken,
        submittedAt: DateTime.now(),
      );

      await ref.read(examRepositoryProvider).submitExamResult(result);

      // Reset active session state
      state = null;

      return result;
    } catch (e) {
      state = currentSession.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final examSessionProvider =
    NotifierProvider<ExamSessionNotifier, ExamSessionState?>(() {
      return ExamSessionNotifier();
    });
