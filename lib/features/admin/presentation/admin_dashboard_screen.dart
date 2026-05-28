import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/result_model.dart';
import '../providers/admin_provider.dart';

final adminResultsProvider = StreamProvider<List<ResultModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('user_exam_results')
      .snapshots()
      .map((snap) {
        final results = snap.docs
            .map((doc) => ResultModel.fromMap(doc.data(), doc.id))
            .toList();
        results.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        return results;
      });
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider).value ?? const [];
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final results = ref.watch(adminResultsProvider).value ?? const <ResultModel>[];
    final students = users.where((user) => user.isStudent).length;
    final teachers = users.where((user) => user.isTeacher).length;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allUsersProvider);
          ref.invalidate(subjectsProvider);
          ref.invalidate(adminResultsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              tr('admin_overview'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('admin_dashboard_hint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            _AdminStatsGrid(
              cards: [
                _AdminStatCard(
                  icon: Icons.group_outlined,
                  value: '${users.length}',
                  label: tr('manage_users'),
                  color: const Color(0xFF1E40AF),
                ),
                _AdminStatCard(
                  icon: Icons.analytics_outlined,
                  value: '${results.length}',
                  label: tr('results'),
                  color: const Color(0xFF4F46E5),
                ),
                _AdminStatCard(
                  icon: Icons.school_outlined,
                  value: '$students',
                  label: tr('total_students'),
                  color: const Color(0xFF0EA5E9),
                ),
                _AdminStatCard(
                  icon: Icons.co_present_outlined,
                  value: '$teachers',
                  label: 'Total Mestre',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AdminStatCard(
              icon: Icons.menu_book_outlined,
              value: '${subjects.length}',
              label: 'Total Materia',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 20),
            _WeeklyActivityChart(results: results),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  const _WeeklyActivityChart({required this.results});

  final List<ResultModel> results;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final count = results.where((result) {
        final submitted = result.submittedAt;
        return submitted.year == day.year &&
            submitted.month == day.month &&
            submitted.day == day.day;
      }).length;
      return _ActivityDay(day: day, count: count);
    });
    final maxCount =
        days.fold<int>(1, (max, day) => day.count > max ? day.count : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('weekly_activity'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBarHeight = constraints.maxHeight - 54;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.map((day) {
                    final normalized = day.count / maxCount;
                    final barHeight = 18 + normalized * (maxBarHeight - 18);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 18,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${day.count}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 18,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(DateFormat('E').format(day.day)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatsGrid extends StatelessWidget {
  const _AdminStatsGrid({required this.cards});

  final List<_AdminStatCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 3 ? 2.2 : 1.55,
          children: cards,
        );
      },
    );
  }
}

class _ActivityDay {
  const _ActivityDay({required this.day, required this.count});

  final DateTime day;
  final int count;
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
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
