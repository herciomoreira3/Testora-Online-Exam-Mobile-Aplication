import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/exam_model.dart';
import '../../../shared/models/result_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/exam_provider.dart';

final studentDashboardResultsProvider = StreamProvider<List<ResultModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(examRepositoryProvider).getStudentExamResults(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class ListExamScreen extends ConsumerWidget {
  const ListExamScreen({super.key});

  String _formatSchedule(DateTime value) {
    return DateFormat('EEE, dd MMM yyyy - HH:mm').format(value);
  }

  String _formatCountdown(DateTime value) {
    final diff = value.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(activeExamsProvider);
    final userAsync = ref.watch(userProfileProvider);
    final resultsAsync = ref.watch(studentDashboardResultsProvider);
    final uid = ref.watch(authRepositoryProvider).currentUid;
    final subjectsAsync = uid == null
        ? const AsyncValue.data([])
        : ref.watch(studentSubjectsProvider(uid));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.school_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(tr('app_name')),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr('profile'),
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: examsAsync.when(
        data: (exams) {
          final user = userAsync.value;
          final results = resultsAsync.value ?? const <ResultModel>[];
          final subjects = subjectsAsync.value ?? const [];
          final assignedSubjectIds = subjects.map((subject) => subject.id).toSet();
          final assignedSubjectNames =
              subjects.map((subject) => subject.name).toSet();
          final completedExamIds =
              results.map((result) => result.examId).toSet();
          final now = DateTime.now();
          final activeExams = exams.where((exam) {
            final assigned = assignedSubjectIds.contains(exam.subjectId) ||
                assignedSubjectNames.contains(exam.subject);
            final notCompleted = !completedExamIds.contains(exam.id);
            final notExpired = now.isBefore(exam.endTime);
            return exam.totalQuestions > 0 && assigned && notCompleted && notExpired;
          }).toList();
          final nextExam = activeExams.isNotEmpty ? activeExams.first : null;
          final completed = results.length;
          final average = results.isEmpty
              ? 0
              : results
                    .map((result) => result.percentage)
                    .reduce((a, b) => a + b) /
                results.length;
          final studyMinutes = results.fold<int>(
            0,
            (sum, result) => sum + (result.timeTaken ~/ 60),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeExamsProvider);
              ref.invalidate(studentDashboardResultsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Text(
                  '${tr('welcome_teacher')}, ${user?.name.split(' ').first ?? tr('student')}!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('student_dashboard_hint'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                if (nextExam != null)
                  _NextExamCard(
                    exam: nextExam,
                    countdown: _formatCountdown(nextExam.startTime),
                    schedule: _formatSchedule(nextExam.startTime),
                    canStart: !now.isBefore(nextExam.startTime) &&
                        now.isBefore(nextExam.endTime),
                    onStart: () => context.push('/take-exam/${nextExam.id}'),
                  )
                else
                  _EmptyStateCard(message: tr('empty_exam')),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF10B981),
                        value: '$completed',
                        label: tr('exams_completed'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF1E40AF),
                        value: average.toStringAsFixed(1),
                        label: tr('avg_score'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.history_rounded,
                  color: const Color(0xFF4F46E5),
                  value: '$studyMinutes',
                  label: tr('study_minutes'),
                ),
                const SizedBox(height: 26),
                _SectionTitle(title: tr('ongoing_exams'), badge: 'LIVE'),
                const SizedBox(height: 12),
                if (activeExams.isEmpty)
                  _EmptyStateCard(message: tr('empty_exam'))
                else
                  ...activeExams.map(
                    (exam) => _ExamListCard(
                      exam: exam,
                      schedule: _formatSchedule(exam.startTime),
                      canStart: !now.isBefore(exam.startTime) &&
                          now.isBefore(exam.endTime),
                      onStart: () => context.push('/take-exam/${exam.id}'),
                    ),
                  ),
                const SizedBox(height: 22),
                _SectionTitle(title: tr('recent_history')),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  _EmptyStateCard(message: tr('no_history'))
                else
                  ...results.take(3).map((result) => _HistoryRow(result: result)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(tr('error_occurred'))),
      ),
    );
  }
}

class _NextExamCard extends StatelessWidget {
  const _NextExamCard({
    required this.exam,
    required this.countdown,
    required this.schedule,
    required this.canStart,
    required this.onStart,
  });

  final ExamModel exam;
  final String countdown;
  final String schedule;
  final bool canStart;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Badge(icon: Icons.calendar_month_outlined, label: tr('upcoming_exam')),
          const SizedBox(height: 16),
          Text(
            exam.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F2F78),
            ),
          ),
          const SizedBox(height: 8),
          Text(schedule, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CountdownBox(value: countdown, label: tr('time_remaining')),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: canStart ? onStart : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(canStart ? tr('start_exam') : tr('not_started')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamListCard extends StatelessWidget {
  const _ExamListCard({
    required this.exam,
    required this.schedule,
    required this.canStart,
    required this.onStart,
  });

  final ExamModel exam;
  final String schedule;
  final bool canStart;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: Color(0xFF00288E), width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.subject.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(exam.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '$schedule | ${exam.duration} ${tr('minutes')} | ${exam.totalQuestions} ${tr('question')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: tr('start_exam'),
            onPressed: canStart ? onStart : null,
            icon: Icon(canStart ? Icons.play_arrow_rounded : Icons.lock_clock),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.result});

  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final passed = result.percentage >= 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (passed ? const Color(0xFF10B981) : Colors.red)
                .withValues(alpha: 0.12),
            child: Text(
              result.percentage.toStringAsFixed(0),
              style: TextStyle(
                color: passed ? const Color(0xFF047857) : Colors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.examTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(DateFormat('dd/MM').format(result.submittedAt)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.badge});

  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFEA580C)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFEA580C),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBox extends StatelessWidget {
  const _CountdownBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}
