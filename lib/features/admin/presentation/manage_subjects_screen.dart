import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/user_model.dart';
import '../providers/admin_provider.dart';

class ManageSubjectsScreen extends ConsumerStatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  ConsumerState<ManageSubjectsScreen> createState() =>
      _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends ConsumerState<ManageSubjectsScreen> {
  Future<void> _openSubjectForm({SubjectModel? subject}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectForm(subject: subject),
    );
  }

  Future<void> _openTeacherAssignment(SubjectModel subject) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TeacherAssignmentSheet(subject: subject),
    );
  }

  Future<void> _openStudentAssignment(SubjectModel subject) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentAssignmentSheet(subject: subject),
    );
  }

  Future<void> _confirmDelete(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('delete_subject')),
        content: Text('${tr('delete_subject_confirm')} ${subject.name}?'),
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
            child: Text(tr('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteSubject(subject.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('subject_deleted'))));
      }
    } catch (error) {
      if (!mounted) return;
      final errorKey = error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              errorKey == 'subject_delete_locked'
                  ? 'subject_delete_locked'
                  : 'error_occurred',
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openSubjectForm(),
        child: const Icon(Icons.add),
      ),
      body: subjectsAsync.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return _EmptySubjects(onAdd: () => _openSubjectForm());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Text(
                tr('manage_subjects'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('manage_subjects_hint'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(context),
                ),
              ),
              const SizedBox(height: 18),
              ...subjects.map((subject) {
                final teacher = users
                    .where((user) => subject.teacherIds.contains(user.uid))
                    .cast<UserModel?>()
                    .firstOrNull;
                final hasAssignedUsers =
                    subject.teacherIds.isNotEmpty ||
                    subject.studentIds.isNotEmpty;
                return _SubjectCard(
                  subject: subject,
                  teacher: teacher,
                  onAdd: subject.teacherIds.isEmpty
                      ? () => _openTeacherAssignment(subject)
                      : () => _openStudentAssignment(subject),
                  onEdit: () => _openSubjectForm(subject: subject),
                  onDelete: hasAssignedUsers
                      ? null
                      : () => _confirmDelete(subject),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.teacher,
    required this.onAdd,
    required this.onEdit,
    this.onDelete,
  });

  final SubjectModel subject;
  final UserModel? teacher;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTeacher = teacher != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryText(context),
                      ),
                    ),
                    if (subject.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subject.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: Icons.school_outlined,
                  label: '${tr('teacher')}: ${teacher?.name ?? '-'}',
                ),
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon: Icons.groups_outlined,
                label: '${subject.studentIds.length}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SubjectActionButton(
                tooltip: hasTeacher
                    ? tr('assign_students')
                    : tr('assign_teacher'),
                icon: hasTeacher
                    ? Icons.group_add_outlined
                    : Icons.person_add_alt_1_outlined,
                onPressed: onAdd,
              ),
              const SizedBox(width: 8),
              _SubjectActionButton(
                tooltip: tr('edit'),
                icon: Icons.edit_outlined,
                onPressed: onEdit,
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                _SubjectActionButton(
                  tooltip: tr('delete'),
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onPressed: onDelete!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.subtleBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _SubjectActionButton extends StatelessWidget {
  const _SubjectActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: resolvedColor,
      style: IconButton.styleFrom(
        backgroundColor: resolvedColor.withValues(alpha: 0.1),
      ),
    );
  }
}

class _SubjectForm extends ConsumerStatefulWidget {
  const _SubjectForm({this.subject});

  final SubjectModel? subject;

  @override
  ConsumerState<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends ConsumerState<_SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.subject?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .saveSubject(
            id: widget.subject?.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeTeacher() async {
    final subject = widget.subject;
    if (subject == null) return;
    await ref
        .read(adminRepositoryProvider)
        .assignTeachersToSubject(subject.id, const []);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final teacher = widget.subject == null
        ? null
        : users
              .where((user) => widget.subject!.teacherIds.contains(user.uid))
              .cast<UserModel?>()
              .firstOrNull;

    return _SheetFrame(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.subject == null ? tr('add_subject') : tr('edit_subject'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: tr('subject')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? tr('required_field')
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: tr('exam_desc')),
              minLines: 3,
              maxLines: 4,
            ),
            if (widget.subject != null) ...[
              const SizedBox(height: 16),
              _AssignedTeacherPanel(
                teacher: teacher,
                onRemove: teacher == null ? null : _removeTeacher,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedTeacherPanel extends StatelessWidget {
  const _AssignedTeacherPanel({required this.teacher, required this.onRemove});

  final UserModel? teacher;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.subtleBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              teacher?.name.isNotEmpty == true
                  ? teacher!.name[0].toUpperCase()
                  : 'M',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('assigned_teacher'),
                  style: TextStyle(
                    color: AppTheme.mutedText(context),
                    fontSize: 12,
                  ),
                ),
                Text(
                  teacher?.name ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: tr('delete'),
            onPressed: onRemove,
            color: Colors.red,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _TeacherAssignmentSheet extends ConsumerStatefulWidget {
  const _TeacherAssignmentSheet({required this.subject});

  final SubjectModel subject;

  @override
  ConsumerState<_TeacherAssignmentSheet> createState() =>
      _TeacherAssignmentSheetState();
}

class _TeacherAssignmentSheetState
    extends ConsumerState<_TeacherAssignmentSheet> {
  final _searchController = TextEditingController();
  String? _selectedTeacherId;
  String _query = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTeacherId = widget.subject.teacherIds.firstOrNull;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedTeacherId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(adminRepositoryProvider).assignTeachersToSubject(
        widget.subject.id,
        [_selectedTeacherId!],
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final teachers = users.where((user) {
      final matchesRole = user.isTeacher;
      final needle = _query.trim().toLowerCase();
      final matchesSearch =
          needle.isEmpty ||
          user.name.toLowerCase().contains(needle) ||
          user.email.toLowerCase().contains(needle);
      return matchesRole && matchesSearch;
    }).toList();

    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr('assign_teacher'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subject.name,
            style: TextStyle(color: AppTheme.mutedText(context)),
          ),
          const SizedBox(height: 14),
          _SearchField(
            controller: _searchController,
            hintText: tr('search_teacher'),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: teachers.isEmpty
                ? Center(child: Text(tr('no_users')))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: teachers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      final selected = teacher.uid == _selectedTeacherId;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(
                            teacher.name.isNotEmpty
                                ? teacher.name[0].toUpperCase()
                                : 'M',
                          ),
                        ),
                        title: Text(teacher.name),
                        subtitle: Text(teacher.email),
                        trailing: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF94A3B8),
                        ),
                        onTap: () {
                          setState(() => _selectedTeacherId = teacher.uid);
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSaving || _selectedTeacherId == null ? null : _save,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_outlined),
            label: Text(tr('save')),
          ),
        ],
      ),
    );
  }
}

class _StudentAssignmentSheet extends ConsumerStatefulWidget {
  const _StudentAssignmentSheet({required this.subject});

  final SubjectModel subject;

  @override
  ConsumerState<_StudentAssignmentSheet> createState() =>
      _StudentAssignmentSheetState();
}

class _StudentAssignmentSheetState
    extends ConsumerState<_StudentAssignmentSheet> {
  final _searchController = TextEditingController();
  final Set<String> _selectedStudentIds = {};
  late Set<String> _assignedStudentIds;
  String _query = '';
  bool _isSaving = false;
  String? _removingStudentId;

  @override
  void initState() {
    super.initState();
    _assignedStudentIds = widget.subject.studentIds.toSet();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedStudentIds.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final updated = {..._assignedStudentIds, ..._selectedStudentIds}.toList();
      await ref
          .read(adminRepositoryProvider)
          .assignStudentsToSubject(widget.subject.id, updated);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeStudent(UserModel student) async {
    setState(() => _removingStudentId = student.uid);
    try {
      final updated = _assignedStudentIds
          .where((studentId) => studentId != student.uid)
          .toList();
      await ref
          .read(adminRepositoryProvider)
          .removeStudentFromSubject(
            subjectId: widget.subject.id,
            studentId: student.uid,
            remainingStudentIds: updated,
          );
      if (mounted) {
        setState(() {
          _assignedStudentIds = updated.toSet();
          _selectedStudentIds.remove(student.uid);
        });
      }
    } finally {
      if (mounted) setState(() => _removingStudentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final assignedStudents = users
        .where((user) => _assignedStudentIds.contains(user.uid))
        .toList();
    final students = users.where((user) {
      final notAssigned = !_assignedStudentIds.contains(user.uid);
      final needle = _query.trim().toLowerCase();
      final matchesSearch =
          needle.isEmpty ||
          user.name.toLowerCase().contains(needle) ||
          user.email.toLowerCase().contains(needle);
      return user.isStudent && notAssigned && matchesSearch;
    }).toList();

    return _SheetFrame(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('assign_students'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subject.name,
              style: TextStyle(color: AppTheme.mutedText(context)),
            ),
            if (assignedStudents.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                tr('assigned_students'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: assignedStudents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = assignedStudents[index];
                    final isRemoving = _removingStudentId == student.uid;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : 'S',
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Text(student.email),
                      trailing: IconButton(
                        tooltip: tr('delete'),
                        color: Colors.red,
                        onPressed: isRemoving || _isSaving
                            ? null
                            : () => _removeStudent(student),
                        icon: isRemoving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            _SearchField(
              controller: _searchController,
              hintText: tr('search_student'),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: students.isEmpty
                  ? Center(child: Text(tr('no_available_students')))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final selected = _selectedStudentIds.contains(
                          student.uid,
                        );
                        return CheckboxListTile(
                          value: selected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(student.name),
                          subtitle: Text(student.email),
                          secondary: CircleAvatar(
                            child: Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : 'S',
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedStudentIds.add(student.uid);
                              } else {
                                _selectedStudentIds.remove(student.uid);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSaving || _selectedStudentIds.isEmpty
                  ? null
                  : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.group_add_outlined),
              label: Text(tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('no_subjects'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(tr('add_subject')),
            ),
          ],
        ),
      ),
    );
  }
}
