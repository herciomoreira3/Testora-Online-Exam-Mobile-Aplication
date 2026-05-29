import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/result_model.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/user_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exam/providers/exam_provider.dart';
import '../providers/professor_exam_provider.dart';

class TeacherResultsScreen extends ConsumerWidget {
  const TeacherResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUid;
    final user = ref.watch(userProfileProvider).value;
    final examsAsync = ref.watch(allExamsProvider);
    final subjects = uid == null
        ? const <SubjectModel>[]
        : ref.watch(teacherSubjectsProvider(uid)).value ??
              const <SubjectModel>[];
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final theme = Theme.of(context);

    final assignedSubjectIds = subjects.map((subject) => subject.id).toSet();
    final selectedSubjectId =
        ref.watch(selectedSubjectOverrideProvider) ??
        user?.selectedSubjectId ??
        '';

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: examsAsync.when(
        data: (exams) {
          final scopedExams = exams.where((exam) {
            final assigned = assignedSubjectIds.contains(exam.subjectId);
            final selected =
                selectedSubjectId.isEmpty ||
                exam.subjectId == selectedSubjectId;
            return assigned && selected && _isCompletedExam(exam);
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Text(
                tr('results'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('teacher_results_hint'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(context),
                ),
              ),
              const SizedBox(height: 18),
              if (scopedExams.isEmpty)
                _EmptyPanel(message: tr('no_done_results'))
              else
                ...scopedExams.map((exam) {
                  final subject = subjects
                      .where((subject) => subject.id == exam.subjectId)
                      .firstOrNull;
                  return _ExamResultsCard(
                    exam: exam,
                    subject: subject,
                    users: users,
                    onOpen: () =>
                        context.push('/prof-dashboard/exam/${exam.id}/results'),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }

  bool _isCompletedExam(ExamModel exam) {
    return exam.isDone ||
        (exam.published && DateTime.now().isAfter(exam.endTime));
  }
}

class _ExamResultsCard extends ConsumerWidget {
  const _ExamResultsCard({
    required this.exam,
    required this.subject,
    required this.users,
    required this.onOpen,
  });

  final ExamModel exam;
  final SubjectModel? subject;
  final List<UserModel> users;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsForTeacherProvider(exam.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: resultsAsync.when(
          data: (results) {
            final ordered = _orderedVisibleResults(results, subject, users);
            final average = ordered.isEmpty
                ? 0.0
                : ordered
                          .map((result) => result.percentage)
                          .reduce((a, b) => a + b) /
                      ordered.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            exam.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: tr('view_results'),
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaPill(
                      icon: Icons.event_available_outlined,
                      label:
                          '${tr('completed_at')}: ${DateFormat('dd/MM/yyyy HH:mm').format(exam.endTime)}',
                    ),
                    _MetaPill(
                      icon: Icons.groups_outlined,
                      label: '${ordered.length} ${tr('student')}',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Metric(
                      label: tr('assigned_students'),
                      value: '${subject?.studentIds.length ?? ordered.length}',
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: tr('avg_score'),
                      value: '${average.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ordered.isEmpty)
                  Text(tr('no_history'))
                else
                  ...ordered
                      .take(5)
                      .map(
                        (result) => _ResultTile(
                          result: result,
                          student: _studentForResult(result, users),
                        ),
                      ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('${tr('error_occurred')}: $error'),
        ),
      ),
    );
  }

  List<ResultModel> _orderedVisibleResults(
    List<ResultModel> results,
    SubjectModel? subject,
    List<UserModel> users,
  ) {
    final assignedIds = subject?.studentIds.toSet() ?? const <String>{};
    final visible = results.where((result) {
      final user = _studentForResult(result, users);
      return assignedIds.isEmpty ||
          assignedIds.contains(result.userId) ||
          user?.isStudent == true;
    }).toList();
    visible.sort(_compareResultScore);
    return visible;
  }

  UserModel? _studentForResult(ResultModel result, List<UserModel> users) {
    return users.where((user) => user.uid == result.userId).firstOrNull;
  }

  int _compareResultScore(ResultModel a, ResultModel b) {
    final byPercentage = b.percentage.compareTo(a.percentage);
    if (byPercentage != 0) return byPercentage;
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return a.submittedAt.compareTo(b.submittedAt);
  }
}

final examResultsForTeacherProvider =
    StreamProvider.family<List<ResultModel>, String>((ref, examId) {
      return ref.watch(examRepositoryProvider).getResultsForExam(examId);
    });

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.student});

  final ResultModel result;
  final UserModel? student;

  @override
  Widget build(BuildContext context) {
    final name = student?.name ?? result.userId;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.subtleBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            foregroundImage: (student?.photoUrl ?? '').isNotEmpty
                ? NetworkImage(student!.photoUrl)
                : null,
            child: (student?.photoUrl ?? '').isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd/MM/yyyy HH:mm').format(result.submittedAt)} - ${_formatDuration(result.timeTaken)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${result.percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds ${tr('seconds')}';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (rest == 0) return '$minutes ${tr('minutes')}';
    return '$minutes ${tr('minutes')} $rest ${tr('seconds')}';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.subtleBackground(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedText(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          const Icon(Icons.bar_chart_outlined, color: Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
