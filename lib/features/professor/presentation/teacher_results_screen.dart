import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/result_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../exam/providers/exam_provider.dart';
import '../providers/professor_exam_provider.dart';

class TeacherResultsScreen extends ConsumerWidget {
  const TeacherResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final examsAsync = user == null
        ? const AsyncValue.data([])
        : ref.watch(myExamsProvider(user.uid));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(tr('results')),
        automaticallyImplyLeading: false,
      ),
      body: examsAsync.when(
        data: (exams) {
          if (exams.isEmpty) {
            return Center(child: Text(tr('no_exams')));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = exams[index];
              return _ExamResultsCard(examId: exam.id, title: exam.title);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }
}

class _ExamResultsCard extends ConsumerWidget {
  const _ExamResultsCard({required this.examId, required this.title});

  final String examId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsForTeacherProvider(examId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: resultsAsync.when(
          data: (results) {
            final average = results.isEmpty
                ? 0.0
                : results
                        .map((result) => result.percentage)
                        .reduce((a, b) => a + b) /
                    results.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Metric(label: tr('student'), value: '${results.length}'),
                    const SizedBox(width: 10),
                    _Metric(label: tr('avg_score'), value: average.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 10),
                if (results.isEmpty)
                  Text(tr('no_history'))
                else
                  ...results.take(5).map((result) => _ResultTile(result: result)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('${tr('error_occurred')}: $error'),
        ),
      ),
    );
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
          borderRadius: BorderRadius.circular(12),
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
  const _ResultTile({required this.result});

  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(result.score.toString())),
      title: Text(result.examTitle),
      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(result.submittedAt)),
      trailing: Text('${result.percentage.toStringAsFixed(1)}%'),
    );
  }
}
