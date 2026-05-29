import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_theme.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/user_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class TeacherStudentsScreen extends ConsumerWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final subjects = user == null
        ? const <SubjectModel>[]
        : ref.watch(teacherSubjectsProvider(user.uid)).value ??
              const <SubjectModel>[];
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final selectedSubjectId =
        ref.watch(selectedSubjectOverrideProvider) ??
        user?.selectedSubjectId ??
        '';
    final theme = Theme.of(context);
    final teacherSubjects = subjects
        .where((subject) => subject.teacherIds.contains(user?.uid))
        .where(
          (subject) =>
              selectedSubjectId.isEmpty || subject.id == selectedSubjectId,
        )
        .toList();
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          Text(
            tr('students'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('teacher_students_hint'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText(context),
            ),
          ),
          const SizedBox(height: 18),
          if (teacherSubjects.isEmpty)
            _EmptyPanel(message: tr('no_subjects'))
          else
            ...teacherSubjects.map((subject) {
              final students = users
                  .where((student) => subject.studentIds.contains(student.uid))
                  .toList();
              students.sort((a, b) => a.name.compareTo(b.name));
              return _SubjectStudentsCard(subject: subject, students: students);
            }),
        ],
      ),
    );
  }
}

class _SubjectStudentsCard extends StatelessWidget {
  const _SubjectStudentsCard({required this.subject, required this.students});

  final SubjectModel subject;
  final List<UserModel> students;

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppTheme.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${students.length} ${tr('student')}',
                        style: TextStyle(color: AppTheme.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderColor(context)),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                tr('no_users'),
                style: TextStyle(color: AppTheme.mutedText(context)),
              ),
            )
          else
            ...students.map((student) => _StudentTile(student: student)),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student});

  final UserModel student;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            foregroundImage: student.photoUrl.isNotEmpty
                ? NetworkImage(student.photoUrl)
                : null,
            child: student.photoUrl.isEmpty
                ? Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : 'S',
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
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.mutedText(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.subtleBackground(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                student.school.isEmpty ? '-' : student.school,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.mutedText(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.groups_outlined, color: AppTheme.mutedText(context)),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: AppTheme.mutedText(context))),
        ],
      ),
    );
  }
}
