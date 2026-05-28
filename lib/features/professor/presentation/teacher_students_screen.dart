import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';

class TeacherStudentsScreen extends ConsumerWidget {
  const TeacherStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    final subjects = user == null
        ? const []
        : ref.watch(teacherSubjectsProvider(user.uid)).value ?? const [];
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final teacherSubjects = subjects
        .where((subject) => subject.teacherIds.contains(user?.uid))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(tr('students')),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tr('teacher_students_hint'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 16),
          if (teacherSubjects.isEmpty)
            _EmptyPanel(message: tr('no_subjects'))
          else
            ...teacherSubjects.map((subject) {
              final students = users
                  .where((student) => subject.studentIds.contains(student.uid))
                  .toList();
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(
                    subject.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${students.length} ${tr('student')}'),
                  children: students.isEmpty
                      ? [ListTile(title: Text(tr('no_users')))]
                      : students
                          .map(
                            (student) => ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  student.name.isNotEmpty
                                      ? student.name[0].toUpperCase()
                                      : 'S',
                                ),
                              ),
                              title: Text(student.name),
                              subtitle: Text(student.email),
                              trailing: Text(student.school),
                            ),
                          )
                          .toList(),
                ),
              );
            }),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}
