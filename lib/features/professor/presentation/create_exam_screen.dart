import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../core/providers/app_preferences_provider.dart';
import '../../admin/providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/professor_exam_provider.dart';

class CreateExamScreen extends ConsumerStatefulWidget {
  const CreateExamScreen({super.key, this.examId});

  final String? examId;

  @override
  ConsumerState<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends ConsumerState<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedSubjectId;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  double _durationMinutes = 60;
  bool _shuffleQuestions = true;
  bool _antiCheatEnabled = true;
  bool _isActive = true;
  int _notificationLeadMinutes = 10;
  bool _isSubmitting = false;
  bool _isLoadingExam = false;

  bool get _isEditing => widget.examId != null;

  DateTime get _endTime =>
      _startTime.add(Duration(minutes: _durationMinutes.round()));

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _isLoadingExam = true;
      _loadExamForEdit();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadExamForEdit() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exams')
          .doc(widget.examId)
          .get();
      if (!mounted) return;

      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('exam_not_found'))));
        context.pop();
        return;
      }

      final startTime = data['startTime'];
      final duration = data['duration'];

      setState(() {
        _titleController.text = (data['title'] ?? '').toString();
        _descController.text = (data['description'] ?? '').toString();
        _selectedSubjectId = data['subjectId']?.toString();
        if (startTime is Timestamp) {
          _startTime = startTime.toDate();
        }
        if (duration is num) {
          _durationMinutes = duration.toDouble().clamp(10.0, 180.0).toDouble();
        }
        _shuffleQuestions = data['shuffleQuestions'] != false;
        _antiCheatEnabled = data['antiCheatEnabled'] != false;
        _isActive = data['isActive'] != false;
        _notificationLeadMinutes =
            int.tryParse(data['notificationLeadMinutes']?.toString() ?? '') ??
            10;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingExam = false);
      }
    }
  }

  Future<void> _pickStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('auth_failed'))));
      }
      setState(() => _isSubmitting = false);
      return;
    }

    final user = ref.read(userProfileProvider).value;
    final role = user?.role;
    final selectedSubjectId =
        ref.read(selectedSubjectOverrideProvider) ??
        user?.selectedSubjectId ??
        '';
    final assignedSubjects = role == 'admin'
        ? ref.read(subjectsProvider).value ?? const []
        : ref.read(teacherSubjectsProvider(uid)).value ?? const [];
    final subjects = role == 'teacher' && selectedSubjectId.isNotEmpty
        ? assignedSubjects
              .where((subject) => subject.id == selectedSubjectId)
              .toList()
        : assignedSubjects;
    final selectedSubject = subjects
        .where((subject) => subject.id == _selectedSubjectId)
        .firstOrNull;
    if (selectedSubject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('select_subject_required'))));
      setState(() => _isSubmitting = false);
      return;
    }

    final subject = selectedSubject.name;
    final nextStatus = role == 'admin' ? 'sending' : 'draft';
    final data = {
      'title': _titleController.text.trim(),
      'subject': subject,
      'subjectId': selectedSubject.id,
      'category': subject,
      'description': _descController.text.trim(),
      'startTime': Timestamp.fromDate(_startTime),
      'endTime': Timestamp.fromDate(_endTime),
      'duration': _durationMinutes.round(),
      'shuffleQuestions': _shuffleQuestions,
      'antiCheatEnabled': _antiCheatEnabled,
      'isActive': _isActive,
      'published': false,
      'status': nextStatus,
      'notificationLeadMinutes': _notificationLeadMinutes,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('exams')
            .doc(widget.examId)
            .update(data);
      } else {
        data.addAll({
          'teacherId': uid,
          'createdBy': uid,
          'ownerId': uid,
          'totalQuestions': 0,
          'studentCount': '0/32',
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        final examRef = await ref
            .read(professorRepositoryProvider)
            .createExam(data);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('exam_created')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (role == 'admin') {
          context.go('/admin/exams/${examRef.id}/manage-questions');
        } else {
          context.go('/prof-dashboard/exam/${examRef.id}/manage-questions');
        }
        return;
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('exam_updated')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (role == 'admin') {
        context.go('/admin/exams');
      } else {
        context.go('/prof-dashboard/exams');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(authRepositoryProvider).currentUid;
    final user = ref.watch(userProfileProvider).value;
    final role = user?.role;
    final activeSubjectId =
        ref.watch(selectedSubjectOverrideProvider) ??
        user?.selectedSubjectId ??
        '';
    final subjectsAsync = role == 'admin'
        ? ref.watch(subjectsProvider)
        : uid == null
        ? const AsyncValue.data([])
        : ref.watch(teacherSubjectsProvider(uid));
    final materialLocalizations = MaterialLocalizations.of(context);
    final dateLabel =
        '${materialLocalizations.formatFullDate(_startTime)} ${materialLocalizations.formatTimeOfDay(TimeOfDay.fromDateTime(_startTime))}';
    final title = _isEditing ? tr('edit_exam') : tr('create_exam');

    if (_isLoadingExam) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return subjectsAsync.when(
      data: (subjects) {
        final scopedSubjects = role == 'teacher' && activeSubjectId.isNotEmpty
            ? subjects
                  .where((subject) => subject.id == activeSubjectId)
                  .toList()
            : subjects;
        if (_selectedSubjectId == null ||
            !scopedSubjects.any(
              (subject) => subject.id == _selectedSubjectId,
            )) {
          _selectedSubjectId = scopedSubjects.firstOrNull?.id;
        }
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr('exam_details'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _titleController,
                      labelText: tr('exam_title'),
                      hintText: tr('exam_title'),
                      prefixIcon: Icons.edit_note_rounded,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? tr('required_field')
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectId,
                      decoration: InputDecoration(
                        labelText: tr('subject'),
                        prefixIcon: const Icon(Icons.menu_book_outlined),
                      ),
                      items: scopedSubjects
                          .map(
                            (subject) => DropdownMenuItem<String>(
                              value: subject.id,
                              child: Text(subject.name),
                            ),
                          )
                          .toList(),
                      onChanged: role == 'teacher'
                          ? null
                          : (value) =>
                                setState(() => _selectedSubjectId = value),
                      validator: (value) => value == null || value.isEmpty
                          ? tr('required_field')
                          : null,
                    ),
                    if (role == 'teacher') ...[
                      const SizedBox(height: 8),
                      Text(
                        tr('teacher_subject_locked'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _descController,
                      labelText: tr('exam_desc'),
                      hintText: tr('exam_desc'),
                      prefixIcon: Icons.notes_rounded,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? tr('required_field')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('schedule'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_available_rounded),
                            title: Text(tr('start_time')),
                            subtitle: Text(dateLabel),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: _pickStartTime,
                          ),
                          const Divider(),
                          Text(
                            '${tr('duration')}: ${_durationMinutes.round()} ${tr('minutes')}',
                            style: theme.textTheme.bodyLarge,
                          ),
                          Slider(
                            value: _durationMinutes,
                            min: 10,
                            max: 180,
                            divisions: 17,
                            label: '${_durationMinutes.round()}',
                            onChanged: (value) =>
                                setState(() => _durationMinutes = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr('randomize_questions')),
                            subtitle: Text(tr('randomize_questions_desc')),
                            value: _shuffleQuestions,
                            onChanged: (v) =>
                                setState(() => _shuffleQuestions = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr('anti_cheat')),
                            subtitle: Text(tr('anti_cheat_desc')),
                            value: _antiCheatEnabled,
                            onChanged: (v) =>
                                setState(() => _antiCheatEnabled = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr('is_active')),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            title: Text(tr('notification_before_exam')),
                            subtitle: Text(
                              '$_notificationLeadMinutes ${tr('minutes')}',
                            ),
                          ),
                          DropdownButtonFormField<int>(
                            initialValue: _notificationLeadMinutes,
                            decoration: InputDecoration(
                              labelText: tr('notification_before_exam'),
                            ),
                            items: [5, 10, 15, 30, 60]
                                .map(
                                  (minutes) => DropdownMenuItem(
                                    value: minutes,
                                    child: Text('$minutes ${tr('minutes')}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _notificationLeadMinutes = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: _isEditing
                          ? tr('save')
                          : tr('continue_add_questions'),
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
