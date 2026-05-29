import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../shared/models/user_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/professor_exam_provider.dart';

class ProfDashboardScreen extends ConsumerWidget {
  const ProfDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(authRepositoryProvider).currentUid;
    final user = ref.watch(userProfileProvider).value;
    if (uid == null) {
      return Scaffold(body: Center(child: Text(tr('auth_failed'))));
    }

    final examsAsync = ref.watch(allExamsProvider);
    final subjectsAsync = ref.watch(teacherSubjectsProvider(uid));
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final theme = Theme.of(context);

    return Scaffold(
      body: examsAsync.when(
        data: (exams) {
          final subjects = subjectsAsync.value ?? const [];
          final assignedSubjectIds = subjects
              .map((subject) => subject.id)
              .toSet();
          final selectedSubjectId =
              ref.watch(selectedSubjectOverrideProvider) ??
              user?.selectedSubjectId ??
              '';
          final scopedExams = exams.where((exam) {
            final assigned = assignedSubjectIds.contains(exam.subjectId);
            final selected =
                selectedSubjectId.isEmpty ||
                exam.subjectId == selectedSubjectId;
            return assigned && selected;
          }).toList();
          final activeExams = scopedExams
              .where((exam) => exam.isActive && exam.published)
              .toList();
          final assignedStudentIds = subjects
              .where(
                (subject) =>
                    selectedSubjectId.isEmpty ||
                    subject.id == selectedSubjectId,
              )
              .expand((subject) => subject.studentIds)
              .toSet();
          final totalStudents = users
              .where(
                (student) =>
                    student.isStudent &&
                    assignedStudentIds.contains(student.uid),
              )
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
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
                      value: '${scopedExams.length}',
                      color: AppTheme.primaryColor,
                    ),
                    _StatCard(
                      icon: Icons.groups_outlined,
                      label: tr('total_students'),
                      value: '$totalStudents',
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
                  TextButton(
                    onPressed: () => context.go('/prof-dashboard/exams'),
                    child: Text(tr('see_all')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (activeExams.isEmpty)
                const _EmptyExamCard()
              else
                ...activeExams.map(
                  (exam) => _TeacherExamCard(
                    title: exam.title,
                    subject: exam.subject,
                    duration: exam.duration,
                    totalQuestions: exam.totalQuestions,
                    onResults: () =>
                        context.push('/prof-dashboard/exam/${exam.id}/results'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
        color: AppTheme.cardBackground(context),
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
                  style: TextStyle(
                    color: AppTheme.mutedText(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
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
    required this.title,
    required this.subject,
    required this.duration,
    required this.totalQuestions,
    required this.onResults,
  });

  final String title;
  final String subject;
  final int duration;
  final int totalQuestions;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
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
                    Text('$duration ${tr('minutes')} - $totalQuestions soal'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExamCard extends StatelessWidget {
  const _EmptyExamCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: AppTheme.mutedText(context)),
          const SizedBox(height: 12),
          Text(
            tr('empty_exam'),
            style: TextStyle(
              color: AppTheme.mutedText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
