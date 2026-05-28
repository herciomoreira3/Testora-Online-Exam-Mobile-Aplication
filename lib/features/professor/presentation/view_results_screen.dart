import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../professor/providers/result_provider.dart';

class ViewResultsScreen extends ConsumerWidget {
  const ViewResultsScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(examResultsProvider(examId));
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('view_results')),
        automaticallyImplyLeading: true,
      ),
      body: resultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(child: Text(tr('no_history')));
          }
          final sorted = results.toList();
          sorted.sort((a, b) => b.score.compareTo(a.score));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = sorted[index];
              return ListTile(
                leading: CircleAvatar(child: Text(r.score.toString())),
                title: Text(r.examTitle),
                subtitle: Text('${tr('duration')}: ${r.timeTaken}'),
                trailing: Text('${r.percentage.toStringAsFixed(1)}%'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
