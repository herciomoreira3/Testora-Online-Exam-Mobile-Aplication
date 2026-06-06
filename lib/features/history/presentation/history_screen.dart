import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../shared/models/exam_model.dart';
import '../../../shared/models/result_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exam/providers/exam_provider.dart';

final studentResultsProvider = StreamProvider<List<ResultModel>>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  return authStateAsync.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(examRepositoryProvider).getStudentExamResults(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes ${tr('minutes')} $remainingSeconds ${tr('seconds')}';
    }
    return '$remainingSeconds ${tr('seconds')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(studentResultsProvider);
    final user = ref.watch(userProfileProvider).value;
    final publishedExams =
        ref.watch(publishedExamsProvider).value ?? const <ExamModel>[];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: resultsAsync.when(
        data: (results) {
          final selectedSubjectId =
              ref.watch(selectedSubjectOverrideProvider) ??
              user?.selectedSubjectId ??
              '';
          final resultSubjectIds = {
            for (final exam in publishedExams) exam.id: exam.subjectId,
          };
          final scopedResults = results.where((result) {
            if (selectedSubjectId.isEmpty) return true;
            final resultSubjectId = result.subjectId.isNotEmpty
                ? result.subjectId
                : resultSubjectIds[result.examId] ?? '';
            return resultSubjectId == selectedSubjectId;
          }).toList()..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

          final completed = scopedResults.length;
          final average = scopedResults.isEmpty
              ? 0.0
              : scopedResults
                        .map((result) => result.percentage)
                        .reduce((a, b) => a + b) /
                    scopedResults.length;
          final bestScore = scopedResults.isEmpty
              ? 0.0
              : scopedResults
                    .map((result) => result.percentage)
                    .reduce((a, b) => a > b ? a : b);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(studentResultsProvider);
              ref.invalidate(publishedExamsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Text(
                  tr('history'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('recent_history'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText(context),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HistoryStatCard(
                        icon: Icons.fact_check_outlined,
                        color: const Color(0xFF10B981),
                        value: '$completed',
                        label: tr('exams_completed'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HistoryStatCard(
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF1E40AF),
                        value: average.toStringAsFixed(1),
                        label: tr('avg_score'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HistoryStatCard(
                  icon: Icons.workspace_premium_outlined,
                  color: const Color(0xFF7C3AED),
                  value: bestScore.toStringAsFixed(1),
                  label: tr('score'),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: tr('history')),
                const SizedBox(height: 12),
                if (scopedResults.isEmpty)
                  _HistoryEmptyState(message: tr('no_history'))
                else
                  ...scopedResults.map(
                    (result) => _HistoryResultCard(
                      result: result,
                      duration: _formatDuration(result.timeTaken),
                    ),
                  ),
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

class _HistoryResultCard extends StatelessWidget {
  const _HistoryResultCard({required this.result, required this.duration});

  final ResultModel result;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassed = result.percentage >= 60.0;
    final statusColor = isPassed ? AppTheme.successColor : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '${result.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.examTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryText(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.calendar_month_outlined,
                      label: DateFormat(
                        'dd/MM/yyyy',
                      ).format(result.submittedAt),
                    ),
                    _MetaChip(icon: Icons.timer_outlined, label: duration),
                    _MetaChip(
                      icon: isPassed
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      label: isPassed ? tr('passed') : tr('failed'),
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  const _HistoryStatCard({
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
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText(context),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.mutedText(context),
                    fontSize: 12,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

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
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF64748B),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 56,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.28),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.mutedText(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
