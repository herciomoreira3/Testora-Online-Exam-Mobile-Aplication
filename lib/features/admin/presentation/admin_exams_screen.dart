import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/exam_model.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../professor/providers/professor_exam_provider.dart';

class AdminExamsScreen extends ConsumerStatefulWidget {
  const AdminExamsScreen({super.key});

  @override
  ConsumerState<AdminExamsScreen> createState() => _AdminExamsScreenState();
}

class _AdminExamsScreenState extends ConsumerState<AdminExamsScreen> {
  String _subjectId = 'all';

  Future<void> _deleteExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_exam')),
        content: Text(
          exam.isDone
              ? '${tr('delete_exam')} ${exam.title}?'
              : tr('delete_exam_confirm'),
        ),
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
      await ref.read(professorRepositoryProvider).deleteExamAsAdmin(exam);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('exam_deleted'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('exam_delete_locked')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _publishExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('publish_exam')),
        content: Text(tr('publish_exam_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('publish')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final uid = ref.read(authRepositoryProvider).currentUid ?? '';
      final subject = ref.read(subjectByIdProvider(exam.subjectId));
      await ref
          .read(professorRepositoryProvider)
          .publishExam(exam: exam, subject: subject, publisherId: uid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('exam_published'))));
    } catch (e) {
      if (!mounted) return;
      final key = e.toString().contains('publish_requires_questions')
          ? 'publish_requires_questions'
          : e.toString().contains('exam_schedule_conflict')
          ? 'exam_schedule_conflict'
          : 'error_occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(key)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(allExamsProvider);
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: examsAsync.when(
        data: (exams) {
          final selectedSubjectName = _subjectId == 'all'
              ? null
              : subjects
                    .where((subject) => subject.id == _subjectId)
                    .map((subject) => subject.name)
                    .firstOrNull;
          final scopedExams = _subjectId == 'all'
              ? exams
              : exams.where((exam) {
                  return exam.subjectId == _subjectId ||
                      exam.subject == selectedSubjectName;
                }).toList();
          final pendingExams = scopedExams
              .where((exam) => exam.isSending && !exam.published)
              .toList();
          final publishedExams = scopedExams
              .where((exam) => exam.published || exam.isDone)
              .toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        tr('admin_exams_hint'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedText(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _subjectId,
                        decoration: InputDecoration(labelText: tr('subject')),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(tr('all')),
                          ),
                          ...subjects.map(
                            (subject) => DropdownMenuItem(
                              value: subject.id,
                              child: Text(subject.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _subjectId = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.borderColor(context),
                          ),
                        ),
                        child: TabBar(
                          labelColor: AppTheme.isDark(context)
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          unselectedLabelColor: AppTheme.isDark(context)
                              ? Colors.white
                              : const Color(0xFF64748B),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorColor: AppTheme.isDark(context)
                              ? Colors.white
                              : theme.colorScheme.primary,
                          tabs: [
                            Tab(
                              text:
                                  '${tr('pending_publish')} (${pendingExams.length})',
                            ),
                            Tab(
                              text:
                                  '${tr('published')} (${publishedExams.length})',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AdminExamList(
                        exams: pendingExams,
                        emptyMessage: tr('no_pending_exams'),
                        onQuestions: (exam) => context.push(
                          '/admin/exams/${exam.id}/manage-questions',
                        ),
                        onEdit: (exam) =>
                            context.push('/admin/exams/${exam.id}/edit'),
                        onResults: (exam) =>
                            context.push('/admin/exams/${exam.id}/results'),
                        onDelete: _deleteExam,
                        onPublish: _publishExam,
                      ),
                      _AdminExamList(
                        exams: publishedExams,
                        emptyMessage: tr('no_published_exams'),
                        onQuestions: (exam) => context.push(
                          '/admin/exams/${exam.id}/manage-questions',
                        ),
                        onEdit: (exam) =>
                            context.push('/admin/exams/${exam.id}/edit'),
                        onResults: (exam) =>
                            context.push('/admin/exams/${exam.id}/results'),
                        onDelete: _deleteExam,
                        onPublish: _publishExam,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }
}

class _AdminExamList extends StatelessWidget {
  const _AdminExamList({
    required this.exams,
    required this.emptyMessage,
    required this.onQuestions,
    required this.onEdit,
    required this.onResults,
    required this.onDelete,
    required this.onPublish,
  });

  final List<ExamModel> exams;
  final String emptyMessage;
  final void Function(ExamModel exam) onQuestions;
  final void Function(ExamModel exam) onEdit;
  final void Function(ExamModel exam) onResults;
  final void Function(ExamModel exam) onDelete;
  final void Function(ExamModel exam) onPublish;

  @override
  Widget build(BuildContext context) {
    if (exams.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
        children: [_EmptyAdminExamCard(message: emptyMessage)],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
      children: [
        ...exams.map(
          (exam) => _AdminExamCard(
            examId: exam.id,
            title: exam.title,
            subject: exam.subject,
            startTime: exam.startTime,
            duration: exam.duration,
            totalQuestions: exam.totalQuestions,
            active: exam.isActive,
            published: exam.published,
            done: exam.isDone,
            sending: exam.isSending,
            onQuestions: () => onQuestions(exam),
            onEdit: () => onEdit(exam),
            onResults: () => onResults(exam),
            onDelete: () => onDelete(exam),
            onPublish: () => onPublish(exam),
          ),
        ),
      ],
    );
  }
}

class _AdminExamCard extends StatelessWidget {
  const _AdminExamCard({
    required this.examId,
    required this.title,
    required this.subject,
    required this.startTime,
    required this.duration,
    required this.totalQuestions,
    required this.active,
    required this.published,
    required this.done,
    required this.sending,
    required this.onQuestions,
    required this.onEdit,
    required this.onResults,
    required this.onDelete,
    required this.onPublish,
  });

  final String examId;
  final String title;
  final String subject;
  final DateTime startTime;
  final int duration;
  final int totalQuestions;
  final bool active;
  final bool published;
  final bool done;
  final bool sending;
  final VoidCallback onQuestions;
  final VoidCallback onEdit;
  final VoidCallback onResults;
  final VoidCallback onDelete;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final canPublish = sending && !published && totalQuestions > 0;

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
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    _StatusPill(
                      active: active,
                      published: published,
                      done: done,
                      sending: sending,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subject, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MetaPill(
                      icon: Icons.schedule_outlined,
                      label: '$duration ${tr('minutes')}',
                    ),
                    const SizedBox(width: 10),
                    _MetaPill(
                      icon: Icons.quiz_outlined,
                      label: '$totalQuestions ${tr('question')}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (done) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(tr('delete')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
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
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: tr('delete_exam'),
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: published
                            ? tr('exam_already_published')
                            : tr('publish_exam'),
                        onPressed: canPublish ? onPublish : null,
                        icon: const Icon(Icons.campaign_outlined),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

class _EmptyAdminExamCard extends StatelessWidget {
  const _EmptyAdminExamCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          const Icon(Icons.fact_check_outlined, size: 38),
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
