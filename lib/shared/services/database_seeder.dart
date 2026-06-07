import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedExamsAndQuestions({String? teacherId}) async {
    final owner = teacherId ?? 'demo-teacher';
    final batch = _firestore.batch();

    final exams = [
      _SeedExam(
        id: 'exam_kalkulus_ii',
        title: 'Matematika Wajib: Kalkulus II',
        subject: 'Matematika',
        description:
            'Exam about derivatives, integrals, and calculus applications.',
        duration: 120,
        status: 'wait',
        scheduledHour: 8,
        studentCount: '0/32',
        questions: [
          _SeedQuestion(
            text:
                "Jika f(x) = 2x^2 - 3x + 5, berapakah nilai turunan pertama f'(x) ketika x = 2?",
            options: ["f'(2) = 5", "f'(2) = 7", "f'(2) = 8", "f'(2) = 11"],
            correctAnswerIndex: 1,
          ),
          _SeedQuestion(
            text: 'Berapakah hasil integral dari (3x^2 - 4x + 2) dx?',
            options: [
              'x^3 - 2x^2 + 2x + C',
              '3x^3 - 4x^2 + 2x + C',
              'x^3 - 4x^2 + 2x + C',
              '3x^3 - 2x^2 + x + C',
            ],
            correctAnswerIndex: 0,
          ),
          _SeedQuestion(
            text:
                'Fungsi f(x) = x^3 - 3x^2 mencapai titik stasioner di x = ...',
            options: [
              'x = 0 dan x = 1',
              'x = 0 dan x = 2',
              'x = 1 dan x = -1',
              'x = 1 dan x = 2',
            ],
            correctAnswerIndex: 1,
          ),
        ],
      ),
      _SeedExam(
        id: 'exam_english_04',
        title: 'Reading Comprehension & Grammar',
        subject: 'B. Inggris - Latihan 04',
        description: 'Latihan kosa kata, pemahaman wacana, dan grammar.',
        duration: 45,
        status: 'ongoing',
        scheduledHour: 9,
        studentCount: '12/32',
        questions: [
          _SeedQuestion(
            text:
                "Select the passive voice of: 'The chef prepares a special dinner.'",
            options: [
              'A special dinner is prepared by the chef.',
              'A special dinner was prepares by the chef.',
              'The chef is preparing a special dinner.',
              'Dinner is prepared nicely.',
            ],
            correctAnswerIndex: 0,
          ),
          _SeedQuestion(
            text: "What is the synonym of the word 'Reluctant'?",
            options: ['Eager', 'Hesitant', 'Happy', 'Determined'],
            correctAnswerIndex: 1,
          ),
        ],
      ),
      _SeedExam(
        id: 'exam_fotosintesis',
        title: 'Kuis Harian: Fotosintesis',
        subject: 'Biologi',
        description: 'Kuis reaksi terang, reaksi gelap, dan kloroplas.',
        duration: 60,
        status: 'ongoing',
        scheduledHour: 11,
        studentCount: '12/32',
        questions: [
          _SeedQuestion(
            text:
                'Klorofil berperan aktif menyerap cahaya matahari pada panjang gelombang ...',
            options: [
              'Hijau dan kuning',
              'Merah dan biru',
              'Inframerah',
              'Ultraviolet saja',
            ],
            correctAnswerIndex: 1,
          ),
        ],
      ),
    ];

    for (final exam in exams) {
      final startTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        exam.scheduledHour,
      );
      final examRef = _firestore.collection('exams').doc(exam.id);
      batch.set(examRef, {
        'title': exam.title,
        'subject': exam.subject,
        'category': exam.subject,
        'description': exam.description,
        'duration': exam.duration,
        'totalQuestions': exam.questions.length,
        'shuffleQuestions': true,
        'antiCheatEnabled': true,
        'isActive': exam.status != 'done',
        'published': exam.status != 'done',
        'status': exam.status,
        'studentCount': exam.studentCount,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(
          startTime.add(Duration(minutes: exam.duration)),
        ),
        'createdBy': owner,
        'teacherId': owner,
        'ownerId': owner,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      for (var i = 0; i < exam.questions.length; i++) {
        final question = exam.questions[i];
        batch.set(examRef.collection('questions').doc('q_${i + 1}'), {
          'questionText': question.text,
          'text': question.text,
          'options': question.options,
          'correctAnswerIndex': question.correctAnswerIndex,
          'point': question.points,
          'points': question.points,
        });
      }
    }

    await batch.commit();
  }
}

class _SeedExam {
  _SeedExam({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.duration,
    required this.status,
    required this.scheduledHour,
    required this.studentCount,
    required this.questions,
  });

  final String id;
  final String title;
  final String subject;
  final String description;
  final int duration;
  final String status;
  final int scheduledHour;
  final String studentCount;
  final List<_SeedQuestion> questions;
}

class _SeedQuestion {
  _SeedQuestion({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });

  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final int points = 5;
}
