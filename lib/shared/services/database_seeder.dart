import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedExamsAndQuestions() async {
    final examsRef = _firestore.collection('exams');

    // 1. Exam: Teste Lian Tetun
    final tetunExamDoc = examsRef.doc('teste_lian_tetun');
    await tetunExamDoc.set({
      'title': 'Teste Lian Tetun',
      'description': 'Teste atu koko ita-boot nia koñesimentu kona-ba Gramátika no Ortografia Lian Tetun nian.',
      'duration': 5,
      'totalQuestions': 3,
      'category': 'Lian Tetun',
      'isActive': true,
    });

    final tetunQuestions = [
      {
        'questionText': 'Lian ofisiál Repúblika Demokrátika Timor-Leste nian mak...',
        'options': ['Inglés no Portugés', 'Tetun no Portugés', 'Tetun no Indonéziu', 'Tetun no Inglés'],
        'correctAnswerIndex': 1,
      },
      {
        'questionText': 'Kartaun identidade ne\'ebé uza ba votasaun naran...',
        'options': ['Kartaun Eleitorál', 'Kartaun BI', 'Pasaporte', 'Kartaun Vasina'],
        'correctAnswerIndex': 0,
      },
      {
        'questionText': 'Kapitál husi nasaun Timor-Leste mak...',
        'options': ['Baucau', 'Same', 'Dili', 'Ermera'],
        'correctAnswerIndex': 2,
      },
    ];

    for (int i = 0; i < tetunQuestions.length; i++) {
      await tetunExamDoc
          .collection('questions')
          .doc('q_${i + 1}')
          .set(tetunQuestions[i]);
    }

    // 2. Exam: Teste Koñesimentu Jerál
    final gkeyExamDoc = examsRef.doc('teste_konhesimentu_jeral');
    await gkeyExamDoc.set({
      'title': 'Teste Koñesimentu Jerál',
      'description': 'Teste kona-ba istória, geografia no kultura jeral Timor-Leste nian.',
      'duration': 10,
      'totalQuestions': 3,
      'category': 'Koñesimentu Jerál',
      'isActive': true,
    });

    final gkeyQuestions = [
      {
        'questionText': 'Se mak Proklamadór Independénsia Timor-Leste nian iha 28 Novembru 1975?',
        'options': ['Nicolau Lobato', 'Francisco Xavier do Amaral', 'José Ramos-Horta', 'Xanana Gusmão'],
        'correctAnswerIndex': 1,
      },
      {
        'questionText': 'Iha tinan hira mak Timor-Leste restaura nia Independénsia?',
        'options': ['1999', '2000', '2002', '2005'],
        'correctAnswerIndex': 2,
      },
      {
        'questionText': 'Foho ne\'ebé aas liu iha Timor-Leste mak...',
        'options': ['Foho Matebian', 'Foho Ramelau', 'Foho Kablaki', 'Foho Loelako'],
        'correctAnswerIndex': 1,
      },
    ];

    for (int i = 0; i < gkeyQuestions.length; i++) {
      await gkeyExamDoc
          .collection('questions')
          .doc('q_${i + 1}')
          .set(gkeyQuestions[i]);
    }
  }
}
