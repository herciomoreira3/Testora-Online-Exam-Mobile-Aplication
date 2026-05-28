import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/exam_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/professor_exam_provider.dart';

class ProfDashboardScreen extends ConsumerWidget {
  const ProfDashboardScreen({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('exam_deleted'))),
      );
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

  Future<void> _publishExam(
    BuildContext context,
    WidgetRef ref,
    ExamModel exam,
  ) async {
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
      final subjects = ref.read(teacherSubjectsProvider(uid)).value ?? const [];
      final subject = subjects
          .where((subject) => subject.id == exam.subjectId)
          .firstOrNull;
      await ref.read(professorRepositoryProvider).publishExam(
            exam: exam,
            subject: subject,
            publisherId: uid,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('exam_published'))),
      );
    } catch (e) {
      if (!context.mounted) return;
      final key = e.toString().contains('publish_requires_questions')
          ? 'publish_requires_questions'
          : 'error_occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(key)), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(authRepositoryProvider).currentUid;
    final user = ref.watch(userProfileProvider).value;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('prof_dashboard'))),
        body: Center(child: Text(tr('auth_failed'))),
      );
    }

    final examsAsync = ref.watch(myExamsProvider(uid));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22CBD5E1),
                    blurRadius: 14,
                    offset: Offset(5, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              tr('app_name'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 30,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: examsAsync.when(
        data: (exams) {
          final activeToday = exams.where((exam) => exam.isActive).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
            children: [
              Text(
                '${tr('welcome_teacher')}, ${user?.name ?? tr('teacher')}',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                tr('teacher_dashboard_hint'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 118,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatCard(
                      icon: Icons.assignment_outlined,
                      label: tr('total_exams'),
                      value: '${exams.length}',
                      color: AppTheme.primaryColor,
                    ),
                    _StatCard(
                      icon: Icons.groups_outlined,
                      label: tr('total_students'),
                      value: '128',
                      color: AppTheme.successColor,
                    ),
                    _StatCard(
                      icon: Icons.bar_chart_rounded,
                      label: tr('results'),
                      value: '86%',
                      color: AppTheme.secondaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('active_exams_today'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(onPressed: () {}, child: Text(tr('see_all'))),
                ],
              ),
              const SizedBox(height: 14),
              if (activeToday.isEmpty)
                _EmptyExamCard(
                  onTap: () => context.push('/prof-dashboard/create-exam'),
                )
              else
                ...activeToday.map(
                  (exam) => _TeacherExamCard(
                    examId: exam.id,
                    title: exam.title,
                    subject: exam.subject,
                    startTime: exam.startTime,
                    duration: exam.duration,
                    totalQuestions: exam.totalQuestions,
                    published: exam.published,
                    onQuestions: () => context.push(
                      '/prof-dashboard/exam/${exam.id}/manage-questions',
                    ),
                    onEdit: () => context.push(
                      '/prof-dashboard/exam/${exam.id}/edit',
                    ),
                    onResults: () =>
                        context.push('/prof-dashboard/exam/${exam.id}/results'),
                    onDelete: () => _deleteExam(context, ref, exam),
                    onPublish: () => _publishExam(context, ref, exam),
                  ),
                ),
              const SizedBox(height: 18),
              _DashedCreateCard(
                onTap: () => context.push('/prof-dashboard/create-exam'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline_rounded),
        label: Text(tr('create_exam')),
        onPressed: () => context.push('/prof-dashboard/create-exam'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FCBD5E1),
            blurRadius: 24,
            offset: Offset(8, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF757684),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF191C1E),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherExamCard extends StatelessWidget {
  const _TeacherExamCard({
    required this.examId,
    required this.title,
    required this.subject,
    required this.startTime,
    required this.duration,
    required this.totalQuestions,
    required this.published,
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
  final bool published;
  final VoidCallback onQuestions;
  final VoidCallback onEdit;
  final VoidCallback onResults;
  final VoidCallback onDelete;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final hasResults = ref.watch(examHasResultsProvider(examId)).value ?? true;
        final canDelete =
            !published && DateTime.now().isBefore(startTime) && !hasResults;
        final canPublish = !published && totalQuestions > 0;

        return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FCBD5E1),
            blurRadius: 22,
            offset: Offset(8, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 118,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryContainer, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('$duration ${tr('minutes')} • $totalQuestions soal'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onResults,
                        child: Text(tr('monitor_live')),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                      tooltip: canDelete
                          ? tr('delete_exam')
                          : tr('exam_delete_locked'),
                      onPressed: canDelete ? onDelete : null,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _DashedCreateCard extends StatelessWidget {
  const _DashedCreateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC4C5D5), width: 1.5),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF1F5F9),
              child: const Icon(Icons.add, color: Color(0xFF757684)),
            ),
            const SizedBox(height: 12),
            Text(
              tr('schedule_another_exam'),
              style: const TextStyle(
                color: Color(0xFF757684),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExamCard extends StatelessWidget {
  const _EmptyExamCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashedCreateCard(onTap: onTap);
  }
}
