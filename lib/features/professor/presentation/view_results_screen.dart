import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/result_model.dart';
import '../../../shared/models/user_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../providers/professor_exam_provider.dart';
import '../../professor/providers/result_provider.dart';

class ViewResultsScreen extends ConsumerWidget {
  const ViewResultsScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsProvider(examId));
    final exams = ref.watch(allExamsProvider).value ?? const [];
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final exam = exams.where((exam) => exam.id == examId).firstOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        title: Text(exam?.title ?? tr('view_results')),
        automaticallyImplyLeading: true,
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(child: Text(tr('no_history')));
          }
          final sorted = results.toList();
          sorted.sort(_compareResultScore);
          final average = sorted.isEmpty
              ? 0.0
              : sorted
                        .map((result) => result.percentage)
                        .reduce((a, b) => a + b) /
                    sorted.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Text(
                tr('view_results'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exam?.subject ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(context),
                ),
              ),
              const SizedBox(height: 18),
              if (exam != null)
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
                      label: '${sorted.length} ${tr('student')}',
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Metric(
                    label: tr('avg_score'),
                    value: '${average.toStringAsFixed(1)}%',
                  ),
                  const SizedBox(width: 10),
                  _Metric(
                    label: tr('top_score'),
                    value: '${sorted.first.percentage.toStringAsFixed(1)}%',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...sorted.map(
                (result) => _ResultDetailTile(
                  index: sorted.indexOf(result) + 1,
                  result: result,
                  student: users
                      .where((user) => user.uid == result.userId)
                      .firstOrNull,
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

  int _compareResultScore(ResultModel a, ResultModel b) {
    final byPercentage = b.percentage.compareTo(a.percentage);
    if (byPercentage != 0) return byPercentage;
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return a.submittedAt.compareTo(b.submittedAt);
  }
}

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

class _ResultDetailTile extends StatelessWidget {
  const _ResultDetailTile({
    required this.index,
    required this.result,
    required this.student,
  });

  final int index;
  final ResultModel result;
  final UserModel? student;

  @override
  Widget build(BuildContext context) {
    final name = student?.name ?? result.userId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            foregroundImage: (student?.photoUrl ?? '').isNotEmpty
                ? NetworkImage(student!.photoUrl)
                : null,
            child: (student?.photoUrl ?? '').isEmpty
                ? Text(
                    '$index',
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
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student?.email ?? result.userId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.schedule_outlined,
                      label: _formatDuration(result.timeTaken),
                    ),
                    _MetaPill(
                      icon: Icons.done_all_outlined,
                      label: DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(result.submittedAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${tr('score')}: ${result.score}',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
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
