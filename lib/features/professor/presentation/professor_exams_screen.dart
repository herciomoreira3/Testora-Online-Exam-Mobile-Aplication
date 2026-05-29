import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/subject_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/professor_exam_provider.dart';

class ProfessorExamsScreen extends ConsumerWidget {
  const ProfessorExamsScreen({super.key});

  Future<void> _deleteExam(
    BuildContext context,
    WidgetRef ref,
    ExamModel exam,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_exam')),
        content: Text(tr('delete_exam_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('no')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(professorRepositoryProvider).deleteExam(exam);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('exam_deleted'))));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('exam_delete_locked')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendExam(
    BuildContext context,
    WidgetRef ref,
    ExamModel exam,
  ) async {
    try {
      await ref.read(professorRepositoryProvider).sendExamToAdmin(exam);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('exam_sent_to_admin'))));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('exam_send_locked')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUid;
    final user = ref.watch(userProfileProvider).value;
    final examsAsync = ref.watch(allExamsProvider);
    final subjects = uid == null
        ? const <SubjectModel>[]
        : ref.watch(teacherSubjectsProvider(uid)).value ??
              const <SubjectModel>[];
    final theme = Theme.of(context);

    final assignedSubjectIds = subjects.map((subject) => subject.id).toSet();
    final selectedSubjectId =
        ref.watch(selectedSubjectOverrideProvider) ??
        user?.selectedSubjectId ??
        '';

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/prof-dashboard/exams/create'),
        child: const Icon(Icons.add),
      ),
      body: examsAsync.when(
        data: (exams) {
          final filtered = exams.where((exam) {
            final assigned = assignedSubjectIds.contains(exam.subjectId);
            final selected =
                selectedSubjectId.isEmpty ||
                exam.subjectId == selectedSubjectId;
            return assigned && selected;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Text(
                tr('manage_exams'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('teacher_exams_hint'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(context),
                ),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                _EmptyProfessorExamCard(
                  onTap: () => context.push('/prof-dashboard/exams/create'),
                )
              else
                ...filtered.map(
                  (exam) => _ProfessorExamCard(
                    exam: exam,
                    onQuestions: () => context.push(
                      '/prof-dashboard/exam/${exam.id}/manage-questions',
                    ),
                    onEdit: () =>
                        context.push('/prof-dashboard/exam/${exam.id}/edit'),
                    onResults: () =>
                        context.push('/prof-dashboard/exam/${exam.id}/results'),
                    onDelete: () => _deleteExam(context, ref, exam),
                    onSend: () => _sendExam(context, ref, exam),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }
}

class _ProfessorExamCard extends ConsumerWidget {
  const _ProfessorExamCard({
    required this.exam,
    required this.onQuestions,
    required this.onEdit,
    required this.onResults,
    required this.onDelete,
    required this.onSend,
  });

  final ExamModel exam;
  final VoidCallback onQuestions;
  final VoidCallback onEdit;
  final VoidCallback onResults;
  final VoidCallback onDelete;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = !exam.published && !exam.isDone;
    final canSend = !exam.published && !exam.isDone && !exam.isSending;
    final canViewResults = exam.isDone;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                _StatusPill(
                  active: exam.isActive,
                  published: exam.published,
                  done: exam.isDone,
                  sending: exam.isSending,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exam.subject,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MetaPill(
                  icon: Icons.schedule_outlined,
                  label: '${exam.duration} ${tr('minutes')}',
                ),
                const SizedBox(width: 10),
                _MetaPill(
                  icon: Icons.quiz_outlined,
                  label: '${exam.totalQuestions} ${tr('question')}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canViewResults ? onResults : null,
                    icon: const Icon(Icons.bar_chart_outlined),
                    label: Text(tr('results')),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: tr('edit_questions'),
                  onPressed: onQuestions,
                  icon: const Icon(Icons.quiz_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: tr('edit_exam'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.settings_outlined),
                ),
                if (!exam.published && !exam.isDone) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: canSend
                        ? tr('send_to_admin')
                        : tr('exam_waiting_publish'),
                    onPressed: canSend ? onSend : null,
                    icon: const Icon(Icons.send_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: canDelete
                        ? tr('delete_exam')
                        : tr('exam_delete_locked'),
                    onPressed: canDelete ? onDelete : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.active,
    required this.published,
    required this.done,
    required this.sending,
  });

  final bool active;
  final bool published;
  final bool done;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF64748B)
        : published
        ? const Color(0xFF10B981)
        : sending
        ? const Color(0xFFF59E0B)
        : active
        ? const Color(0xFF4F46E5)
        : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        done
            ? tr('exam_done')
            : published
            ? tr('published')
            : sending
            ? tr('sending')
            : active
            ? tr('draft')
            : tr('inactive'),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyProfessorExamCard extends StatelessWidget {
  const _EmptyProfessorExamCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline, size: 38),
            const SizedBox(height: 10),
            Text(tr('create_exam')),
          ],
        ),
      ),
    );
  }
}
