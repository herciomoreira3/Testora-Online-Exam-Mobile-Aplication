import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exam_provider.dart';
import '../providers/timer_provider.dart';
import '../../../core/themes/app_theme.dart';

class TakeExamScreen extends ConsumerStatefulWidget {
  final String examId;

  const TakeExamScreen({super.key, required this.examId});

  @override
  ConsumerState<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends ConsumerState<TakeExamScreen>
    with WidgetsBindingObserver {
  bool _started = false;
  bool _isAutoSubmitting = false;
  bool _isSubmittingExam = false;
  String? _blockMessageKey;
  late final ScrollController _questionScrollController;
  final Map<String, Uint8List> _decodedImageCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _questionScrollController = ScrollController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = ref.read(examSessionProvider);
    if (session == null || !session.exam.antiCheatEnabled || _isAutoSubmitting) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _handleAntiCheatViolation(state.name);
    }
  }

  Future<void> _handleAntiCheatViolation(String lifecycleState) async {
    if (_isAutoSubmitting) return;
    _isAutoSubmitting = true;
    final session = ref.read(examSessionProvider);
    final userId = ref.read(authRepositoryProvider).currentUid;

    if (session != null) {
      try {
        await FirebaseFirestore.instance.collection('exam_logs').add({
          'examId': session.exam.id,
          'examTitle': session.exam.title,
          'studentId': userId,
          'userId': userId,
          'type': 'app_switch',
          'message': 'Student left exam screen: $lifecycleState',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Submission must still continue even if the audit log cannot be saved.
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('anti_cheat_violation')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _submitAndNavigate();
  }

  Future<void> _submitAndNavigate() async {
    if (_isSubmittingExam) return;
    _isSubmittingExam = true;
    try {
      final result = await ref.read(examSessionProvider.notifier).submit();
      if (mounted) {
        context.go('/result', extra: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('error_occurred')),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/home');
      }
    }
  }

  Future<void> _startExamIfAllowed(dynamic exam) async {
    final now = DateTime.now();
    if (now.isBefore(exam.startTime)) {
      setState(() => _blockMessageKey = 'exam_not_started');
      return;
    }
    if (now.isAfter(exam.endTime)) {
      setState(() => _blockMessageKey = 'exam_expired');
      return;
    }
    final userId = ref.read(authRepositoryProvider).currentUid;
    if (userId == null) {
      setState(() => _blockMessageKey = 'auth_failed');
      return;
    }
    final submitted = await ref
        .read(examRepositoryProvider)
        .hasStudentSubmittedExam(userId, exam.id);
    if (submitted) {
      setState(() => _blockMessageKey = 'exam_already_submitted');
      return;
    }
    await ref.read(examSessionProvider.notifier).startSession(exam, _autoSubmit);
  }

  void _autoSubmit() async {
    if (!mounted) return;

    // Automatically submit when timer hits zero
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tempu remata! Entrega automatiku...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await _submitAndNavigate();
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('submit')),
        content: Text(tr('confirm_submit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('no')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              _executeSubmit();
            },
            child: Text(tr('yes')),
          ),
        ],
      ),
    );
  }

  void _executeSubmit() async {
    await _submitAndNavigate();
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sai husi Teste?'),
        content: const Text(
          'Resposta nebe ita boot hatan ona sei entrega agora, no teste sei remata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('no')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _submitAndNavigate();
            },
            child: const Text('Sai'),
          ),
        ],
      ),
    );
  }

  void _goToPreviousQuestion() {
    ref.read(examSessionProvider.notifier).previousQuestion();
    _scrollQuestionToTop();
  }

  void _goToNextQuestion() {
    ref.read(examSessionProvider.notifier).nextQuestion();
    _scrollQuestionToTop();
  }

  void _scrollQuestionToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_questionScrollController.hasClients) return;
      _questionScrollController.jumpTo(0);
    });
  }

  Widget _questionImage(dynamic question) {
    if (question.imageUrl != null && question.imageUrl!.isNotEmpty) {
      return Image.network(
        key: ValueKey(question.imageUrl),
        question.imageUrl!,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    if (question.imageData != null && question.imageData!.isNotEmpty) {
      final bytes = _decodedImageCache.putIfAbsent(
        question.id,
        () => base64Decode(question.imageData!),
      );
      return Image.memory(
        bytes,
        key: ValueKey(question.id),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageError(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _imageError() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      color: const Color(0xFFF1F5F9),
      child: Text(tr('image_load_failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(activeExamsProvider).value;
    final exam = exams?.firstWhere(
      (e) => e.id == widget.examId,
      orElse: () => throw 'Exam not found',
    );
    final session = ref.watch(examSessionProvider);
    final theme = Theme.of(context);

    // Synchronously initialize the exam session once the exam data is ready
    if (exam != null && !_started) {
      _started = true;
      Future.microtask(() {
        _startExamIfAllowed(exam);
      });
    }

    if (_blockMessageKey != null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('app_name'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock, size: 56),
                const SizedBox(height: 14),
                Text(
                  tr(_blockMessageKey!),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: Text(tr('home')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (session == null || session.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Load pergunta sira...'),
            ],
          ),
        ),
      );
    }

    final currentQuestion = session.questions[session.currentIndex];
    final progressPercentage = session.questions.isNotEmpty
        ? (session.answers.length / session.questions.length)
        : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(session.exam.title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _showExitConfirmation,
          ),
          actions: [
            const _ExamTimerBadge(),
          ],
        ),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progressive linear percentage progress bar
                LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Question index tracker
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tr('question')} ${session.currentIndex + 1} / ${session.questions.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Hatan: ${session.answers.length} / ${session.questions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive question workspace
                Expanded(
                  child: SingleChildScrollView(
                    key: ValueKey(currentQuestion.id),
                    controller: _questionScrollController,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question Card
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if ((currentQuestion.imageUrl != null &&
                                        currentQuestion.imageUrl!.isNotEmpty) ||
                                    (currentQuestion.imageData != null &&
                                        currentQuestion
                                            .imageData!
                                            .isNotEmpty)) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: _questionImage(currentQuestion),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                Text(
                                  currentQuestion.questionText,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    height: 1.5,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Options cards mapping
                        ...List.generate(currentQuestion.options.length, (
                          optIdx,
                        ) {
                          final optionText = currentQuestion.options[optIdx];
                          final isSelected =
                              session.answers[currentQuestion.id] == optIdx;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                ref
                                    .read(examSessionProvider.notifier)
                                    .selectOption(currentQuestion.id, optIdx);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.06,
                                        )
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Radio circle design
                                    Container(
                                      height: 22,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : const Color(0xFF64748B),
                                          width: isSelected ? 6.5 : 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Floating next/prev footer toolbar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button
                      TextButton.icon(
                        onPressed: session.currentIndex > 0
                            ? _goToPreviousQuestion
                            : null,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                        ),
                        label: const Text('Kotuk'),
                      ),

                      // Submit button for last question or general shortcut
                      if (session.currentIndex == session.questions.length - 1)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          label: Text(tr('submit')),
                          onPressed: _confirmSubmit,
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          label: const Text('Oin-husi'),
                          onPressed: _goToNextQuestion,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Fullscreen loading overlay during submission
            if (session.isSubmitting)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            tr('loading'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExamTimerBadge extends ConsumerWidget {
  const _ExamTimerBadge();

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingTime = ref.watch(examTimerProvider);
    final theme = Theme.of(context);
    final isUrgent = remainingTime < 60;
    final color = isUrgent ? Colors.red : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUrgent ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_on_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _formatTimer(remainingTime),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
