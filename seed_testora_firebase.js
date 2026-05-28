const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const SERVICE_ACCOUNT_PATH = path.resolve(
  __dirname,
  'testora-ee95f-firebase-adminsdk-fbsvc-5c8add13f2.json',
);

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error('Service account file not found:', SERVICE_ACCOUNT_PATH);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)),
});

const auth = admin.auth();
const db = admin.firestore();

const USERS = [
  {
    email: 'student@testora.com',
    password: 'password123',
    name: 'Andi Pratama',
    role: 'student',
    school: 'Kelas 12-A',
  },
  {
    email: 'teacher@testora.com',
    password: 'password123',
    name: 'Sarah Pratama',
    role: 'teacher',
    school: 'Testora Academy',
  },
  {
    email: 'admin@testora.com',
    password: 'password123',
    name: 'Administrator Utama',
    role: 'admin',
    school: 'Testora Academy',
  },
];

const EXAMS = [
  {
    id: 'exam_kalkulus_ii',
    title: 'Matematika Wajib: Kalkulus II',
    subject: 'Matematika',
    description: 'Ujian mengenai pemahaman turunan, integral, dan aplikasi kalkulus.',
    duration: 120,
    status: 'wait',
    hour: 8,
    studentCount: '0/32',
    questions: [
      {
        text: "Jika f(x) = 2x^2 - 3x + 5, berapakah nilai turunan pertama f'(x) ketika x = 2?",
        options: ["f'(2) = 5", "f'(2) = 7", "f'(2) = 8", "f'(2) = 11"],
        correctAnswerIndex: 1,
      },
      {
        text: 'Berapakah hasil integral dari (3x^2 - 4x + 2) dx?',
        options: [
          'x^3 - 2x^2 + 2x + C',
          '3x^3 - 4x^2 + 2x + C',
          'x^3 - 4x^2 + 2x + C',
          '3x^3 - 2x^2 + x + C',
        ],
        correctAnswerIndex: 0,
      },
      {
        text: 'Fungsi f(x) = x^3 - 3x^2 mencapai titik stasioner di x = ...',
        options: [
          'x = 0 dan x = 1',
          'x = 0 dan x = 2',
          'x = 1 dan x = -1',
          'x = 1 dan x = 2',
        ],
        correctAnswerIndex: 1,
      },
    ],
  },
  {
    id: 'exam_english_04',
    title: 'Reading Comprehension & Grammar',
    subject: 'B. Inggris - Latihan 04',
    description: 'Latihan kosa kata bahasa Inggris, pemahaman wacana, dan tata bahasa pasif.',
    duration: 45,
    status: 'ongoing',
    hour: 9,
    studentCount: '12/32',
    questions: [
      {
        text: "Select the passive voice of: 'The chef prepares a special dinner.'",
        options: [
          'A special dinner is prepared by the chef.',
          'A special dinner was prepares by the chef.',
          'The chef is preparing a special dinner.',
          'Dinner is prepared nicely.',
        ],
        correctAnswerIndex: 0,
      },
      {
        text: "What is the synonym of the word 'Reluctant'?",
        options: ['Eager', 'Hesitant', 'Happy', 'Determined'],
        correctAnswerIndex: 1,
      },
    ],
  },
  {
    id: 'exam_fotosintesis',
    title: 'Kuis Harian: Fotosintesis',
    subject: 'Biologi',
    description: 'Kuis mengenai reaksi terang, reaksi gelap, kloroplas dan metabolisme sel tumbuhan.',
    duration: 60,
    status: 'ongoing',
    hour: 11,
    studentCount: '12/32',
    questions: [
      {
        text: 'Klorofil pada tumbuhan hijau berperan aktif menyerap cahaya matahari pada panjang gelombang ...',
        options: ['Hijau dan kuning', 'Merah dan biru', 'Inframerah', 'Ultraviolet saja'],
        correctAnswerIndex: 1,
      },
    ],
  },
];

async function upsertUser({ email, password, name, role, school }) {
  let user;
  try {
    user = await auth.createUser({ email, password, displayName: name });
    console.log('Created user:', email);
  } catch (error) {
    if (error.code !== 'auth/email-already-exists') throw error;
    user = await auth.getUserByEmail(email);
    console.log('User exists:', email);
  }

  await db.collection('users').doc(user.uid).set(
    {
      uid: user.uid,
      email,
      name,
      school,
      role,
      language: 'tet',
      photoUrl: '',
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return user.uid;
}

async function seedExams(teacherId) {
  const now = new Date();
  const batch = db.batch();

  for (const exam of EXAMS) {
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), exam.hour, 0, 0);
    const end = new Date(start.getTime() + exam.duration * 60 * 1000);
    const examRef = db.collection('exams').doc(exam.id);

    batch.set(
      examRef,
      {
        title: exam.title,
        subject: exam.subject,
        category: exam.subject,
        description: exam.description,
        duration: exam.duration,
        totalQuestions: exam.questions.length,
        shuffleQuestions: true,
        antiCheatEnabled: true,
        isActive: exam.status !== 'done',
        published: exam.status !== 'done',
        status: exam.status,
        studentCount: exam.studentCount,
        startTime: admin.firestore.Timestamp.fromDate(start),
        endTime: admin.firestore.Timestamp.fromDate(end),
        createdBy: teacherId,
        teacherId,
        ownerId: teacherId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    exam.questions.forEach((question, index) => {
      batch.set(
        examRef.collection('questions').doc(`q_${index + 1}`),
        {
          questionText: question.text,
          text: question.text,
          options: question.options,
          correctAnswerIndex: question.correctAnswerIndex,
          point: 5,
          points: 5,
        },
        { merge: true },
      );
    });
  }

  await batch.commit();
}

(async () => {
  try {
    const created = {};
    for (const user of USERS) {
      created[user.role] = await upsertUser(user);
    }

    await seedExams(created.teacher);
    console.log('Seed complete.');
    console.log('Demo logins:');
    console.log('student@testora.com / password123');
    console.log('teacher@testora.com / password123');
    console.log('admin@testora.com / password123');
  } catch (error) {
    console.error(error);
    process.exitCode = 1;
  } finally {
    await admin.app().delete();
  }
})();
