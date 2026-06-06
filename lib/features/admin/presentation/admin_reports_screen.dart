import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/result_model.dart';
import '../../../shared/models/user_model.dart';
import '../../professor/providers/professor_exam_provider.dart';
import '../providers/admin_provider.dart';

final adminAllResultsProvider = StreamProvider<List<ResultModel>>((ref) {
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

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String _subjectId = 'all';
  String _examId = 'all';
  String _studentId = 'all';
  bool _isExporting = false;

  Future<void> _pickStudent(List<UserModel> students) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _StudentPickerSheet(students: students, selectedId: _studentId),
    );
    if (selected != null) setState(() => _studentId = selected);
  }

  Future<void> _exportPdf(
    List<_ReportRow> rows,
    String subjectLabel,
    String examLabel,
    String studentLabel,
  ) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('no_report_data'))));
      return;
    }

    setState(() => _isExporting = true);
    final doc = pw.Document();
    try {
      final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(
        DateTime.now(),
      );
      doc.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
          build: (context) => [
            _pdfReportHeader(generatedAt: generatedAt),
            pw.SizedBox(height: 14),
            _pdfFilterSummary(
              subjectLabel: subjectLabel,
              examLabel: examLabel,
              studentLabel: studentLabel,
              totalRows: rows.length,
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF00288E),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
              ),
              headers: [
                tr('student_name'),
                tr('email'),
                tr('exam_title'),
                tr('subject'),
                tr('score'),
                '%',
                tr('schedule'),
              ],
              data: rows
                  .map(
                    (row) => [
                      row.studentName,
                      row.studentEmail,
                      row.examTitle,
                      row.subject,
                      row.score,
                      row.percentage,
                      row.date,
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'testora-report.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('pdf_export_ready'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tr('pdf_export_failed')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exams = ref.watch(allExamsProvider).value ?? const [];
    final results =
        ref.watch(adminAllResultsProvider).value ?? const <ResultModel>[];
    final users = ref.watch(allUsersProvider).value ?? const <UserModel>[];
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final theme = Theme.of(context);

    final subjectLabel = _subjectId == 'all'
        ? tr('all')
        : subjects
                  .where((subject) => subject.id == _subjectId)
                  .map((subject) => subject.name)
                  .firstOrNull ??
              tr('all');
    final subjectExamIds = _subjectId == 'all'
        ? exams.map((exam) => exam.id).toSet()
        : exams
              .where(
                (exam) =>
                    exam.subjectId == _subjectId ||
                    exam.subject == subjectLabel,
              )
              .map((exam) => exam.id)
              .toSet();
    final filteredExams = _subjectId == 'all'
        ? exams
        : exams.where((exam) => subjectExamIds.contains(exam.id)).toList();
    final examLabel = _examId == 'all'
        ? tr('all')
        : exams
                  .where((exam) => exam.id == _examId)
                  .map((exam) => exam.title)
                  .firstOrNull ??
              tr('all');
    final assignedStudentIds = _subjectId == 'all'
        ? users.where((user) => user.isStudent).map((user) => user.uid).toSet()
        : subjects
              .where((subject) => subject.id == _subjectId)
              .expand((subject) => subject.studentIds)
              .toSet();
    final studentOptions = users
        .where(
          (user) => user.isStudent && assignedStudentIds.contains(user.uid),
        )
        .toList();
    if (_studentId != 'all' &&
        !studentOptions.any((student) => student.uid == _studentId)) {
      _studentId = 'all';
    }
    final studentLabel = _studentId == 'all'
        ? tr('all')
        : studentOptions
                  .where((student) => student.uid == _studentId)
                  .map((student) => student.name)
                  .firstOrNull ??
              tr('all');
    final rows = results
        .where((result) {
          final matchesSubject =
              _subjectId == 'all' || subjectExamIds.contains(result.examId);
          final matchesExam = _examId == 'all' || result.examId == _examId;
          final matchesStudent =
              _studentId == 'all' || result.userId == _studentId;
          return matchesSubject && matchesExam && matchesStudent;
        })
        .map((result) {
          final user = users.where((u) => u.uid == result.userId).firstOrNull;
          final exam = exams.where((e) => e.id == result.examId).firstOrNull;
          return _ReportRow(
            studentName: user?.name ?? result.userId,
            studentEmail: user?.email ?? '-',
            examTitle: result.examTitle,
            subject: exam?.subject ?? '-',
            score: result.score.toString(),
            percentage: result.percentage.toStringAsFixed(1),
            date: DateFormat('dd/MM/yyyy HH:mm').format(result.submittedAt),
          );
        })
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            tr('reports'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryText(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr('reports_hint'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText(context),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _subjectId,
            decoration: InputDecoration(labelText: tr('subject')),
            items: [
              DropdownMenuItem(value: 'all', child: Text(tr('all'))),
              ...subjects.map(
                (subject) => DropdownMenuItem(
                  value: subject.id,
                  child: Text(subject.name),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _subjectId = value;
                  _examId = 'all';
                  _studentId = 'all';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          _StudentFilterButton(
            label: studentLabel,
            onTap: () => _pickStudent(studentOptions),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _examId,
            decoration: InputDecoration(labelText: tr('manage_exams')),
            items: [
              DropdownMenuItem(value: 'all', child: Text(tr('all'))),
              ...filteredExams.map(
                (exam) =>
                    DropdownMenuItem(value: exam.id, child: Text(exam.title)),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _examId = value);
            },
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isExporting
                ? null
                : () => _exportPdf(
                    rows,
                    subjectLabel,
                    examLabel,
                    studentLabel,
                  ),
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(tr('export_pdf')),
          ),
          const SizedBox(height: 18),
          _ReportTable(rows: rows),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.rows});

  final List<_ReportRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Text(tr('no_history')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(tr('student_name'))),
            DataColumn(label: Text(tr('email'))),
            DataColumn(label: Text(tr('exam_title'))),
            DataColumn(label: Text(tr('subject'))),
            DataColumn(label: Text(tr('score'))),
            const DataColumn(label: Text('%')),
            DataColumn(label: Text(tr('schedule'))),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row.studentName)),
                    DataCell(Text(row.studentEmail)),
                    DataCell(Text(row.examTitle)),
                    DataCell(Text(row.subject)),
                    DataCell(Text(row.score)),
                    DataCell(Text(row.percentage)),
                    DataCell(Text(row.date)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

pw.Widget _pdfReportHeader({required String generatedAt}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 54,
            height: 54,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF00288E),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'T',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TESTORA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF00288E),
                  ),
                ),
                pw.Text(
                  'Academic Examination Report',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColor.fromInt(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                tr('reports'),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                generatedAt,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Container(height: 2, color: PdfColor.fromInt(0xFF00288E)),
    ],
  );
}

pw.Widget _pdfFilterSummary({
  required String subjectLabel,
  required String examLabel,
  required String studentLabel,
  required int totalRows,
}) {
  pw.Widget item(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF64748B),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        tr('reports_hint'),
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColor.fromInt(0xFF475569),
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Row(
        children: [
          pw.Expanded(child: item(tr('subject'), subjectLabel)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: item(tr('manage_exams'), examLabel)),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(child: item(tr('student'), studentLabel)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: item(tr('total_students'), totalRows.toString())),
        ],
      ),
    ],
  );
}

class _StudentFilterButton extends StatelessWidget {
  const _StudentFilterButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: tr('student'),
          prefixIcon: const Icon(Icons.person_search_outlined),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _StudentPickerSheet extends StatefulWidget {
  const _StudentPickerSheet({required this.students, required this.selectedId});

  final List<UserModel> students;
  final String selectedId;

  @override
  State<_StudentPickerSheet> createState() => _StudentPickerSheetState();
}

class _StudentPickerSheetState extends State<_StudentPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final students = widget.students.where((student) {
      return needle.isEmpty ||
          student.name.toLowerCase().contains(needle) ||
          student.email.toLowerCase().contains(needle);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('student'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: tr('search_student'),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined),
                    title: Text(tr('all')),
                    trailing: widget.selectedId == 'all'
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, 'all'),
                  ),
                  ...students.map(
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
                      trailing: widget.selectedId == student.uid
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, student.uid),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow {
  const _ReportRow({
    required this.studentName,
    required this.studentEmail,
    required this.examTitle,
    required this.subject,
    required this.score,
    required this.percentage,
    required this.date,
  });

  final String studentName;
  final String studentEmail;
  final String examTitle;
  final String subject;
  final String score;
  final String percentage;
  final String date;
}
