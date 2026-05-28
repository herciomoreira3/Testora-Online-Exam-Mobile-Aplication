/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export type UserRole = 'student' | 'teacher' | 'admin';
export type AppLang = 'id' | 'en' | 'tt'; // id: Indonesia, en: English, tt: Tetun

export interface User {
  email: string;
  fullName: string;
  role: UserRole;
  avatarUrl?: string;
}

export interface Question {
  id: string;
  text: string;
  options: { key: string; text: string }[];
  correctAnswer: string;
  image?: string;
  points: number;
}

export interface Exam {
  id: string;
  title: string;
  subject: string;
  description: string;
  duration: number; // in minutes
  randomize: boolean;
  antiCheat: boolean;
  questions: Question[];
  status: 'wait' | 'ongoing' | 'done';
  scheduledDate?: string;
  scheduledTime?: string;
  studentCount?: string;
}

export interface ExamAttempt {
  examId: string;
  examTitle: string;
  subject: string;
  answers: Record<string, string>; // questionId -> optionKey
  flagged: Record<string, boolean>; // questionId -> isFlagged
  timeLeft: number; // in seconds
  cheatingAttempts: number;
  durationSpent: number; // in seconds
  isSubmitted: boolean;
  score?: number;
}

export interface ExamHistoryItem {
  id: string;
  subject: string;
  title: string;
  date: string;
  score: number;
  maxScore: number;
  status: 'Lulus' | 'Remedial' | 'Peninjauan' | 'Passed' | 'Failed';
}

export type ViewState = 
  | 'splash'
  | 'auth'
  | 'student_dashboard'
  | 'teacher_dashboard'
  | 'admin_dashboard'
  | 'exam_session'
  | 'exam_result'
  | 'create_exam'
  | 'add_question'
  | 'profile_settings';

// Core translations mapping
export const TRANSLATIONS: Record<AppLang, Record<string, string>> = {
  id: {
    tagline: "Ujian Online yang Aman & Adil",
    taglineSub: "Ujian Online ne'ebé Seguru & Justu", // Indonesian visual shows this italic tagline
    systemTitle: "Sistem Ujian Akademik Terpercaya",
    btnSubmitLogin: "Masuk",
    btnSubmitRegister: "Daftar Akun",
    emailPlaceholder: "nama@email.com",
    passwordPlaceholder: "••••••••",
    forgotPass: "Lupa Password?",
    orContinueWith: "Atau lanjutkan dengan",
    googleAccount: "Google Account",
    noAccount: "Belum punya akun?",
    haveAccount: "Sudah punya akun?",
    fullname: "Nama Lengkap",
    roleLabel: "Pilih Peran",
    roleGuru: "Guru",
    roleMurid: "Murid",
    roleAdmin: "Administrator",
    welcomeTitle: "Selamat pagi",
    welcomeSubtitle: "Siapkan dirimu untuk meraih hasil terbaik hari ini.",
    upcomingBadge: "Ujian Selanjutnya",
    studyStats: "Statistik Belajar",
    examsCompleted: "Ujian Selesai",
    avgScore: "Rata-rata Nilai",
    studyMinutes: "Menit Belajar",
    ongoingTitle: "Ujian Sedang Berlangsung",
    btnStartExam: "Mulai Sekarang",
    examHistory: "Riwayat Ujian",
    seeAll: "Lihat Semua",
    thSubject: "Nama Mata Pelajaran",
    thDate: "Tanggal Selesai",
    thScore: "Skor",
    thStatus: "Status",
    navHome: "Home",
    navExams: "Ujian",
    navHistory: "Riwayat",
    navProfile: "Profil",
    flagBtn: "Tandai",
    timeRemaining: "Tersisa",
    pointsWeight: "Points/Bobot",
    prevBtn: "Sebelumnya",
    nextBtn: "Selanjutnya",
    autoSaved: "Jawaban tersimpan otomatis",
    submitConfirm: "Apakah Anda yakin ingin mengakhiri ujian ini? Pastikan semua jawaban telah diperiksa.",
    submittingStatus: "Jawaban Anda sedang diunggah...",
    langSettings: "Bahasa / Language",
    darkMode: "Mode Gelap",
    notifSettings: "Notifikasi & Keamanan",
    notifExams: "Notifikasi Ujian",
    notifExamsSub: "Peringatan jadwal & hasil",
    changePass: "Ubah Kata Sandi",
    verifyAccount: "Verifikasi Akun",
    supportHelp: "Pusat Bantuan",
    termsCond: "Syarat & Ketentuan",
    logoutBtn: "Keluar dari Aplikasi",
    examCompletedBadge: "UJIAN SELESAI",
    congratsTitle: "Luar Biasa",
    congratsSubtitle: "Kamu telah menyelesaikan ujian ini.",
    reviewPerformance: "Ringkasan Performa",
    accuracy: "Akurasi Jawaban",
    timeManagement: "Manajemen Waktu",
    btnReview: "Lihat Pembahasan",
    btnCertificate: "Sertifikat",
    timeSpent: "Waktu Pengerjaan",
    rankClass: "Peringkat Kelas",
    qListTitle: "Daftar Pertanyaan",
    correctLabel: "Benar",
    wrongLabel: "Salah",
    showMore: "Tampilkan Lebih Banyak",
    backToDashboard: "Kembali ke Dashboard",
    teacherWelcome: "Selamat Datang, Bu Sarah",
    teacherSub: "Siap untuk memantau perkembangan akademik siswa hari ini?",
    totalExams: "Total Ujian",
    totalStudents: "Total Siswa",
    needReview: "Perlu Review",
    activeExamsToday: "Ujian Aktif Hari Ini",
    studentAttendance: "Kehadiran Siswa",
    monitorLive: "Pantau Live",
    schedulePlaceholder: "Jadwalkan Ujian Lainnya",
    btnCreateExam: "+ Buat Ujian Baru",
    breadcrumbDashboard: "Dashboard",
    breadcrumbNewExam: "Buat Ujian Baru",
    configNewExam: "Konfigurasi Ujian Baru",
    configSub: "Lengkapi detail ujian untuk melanjutkan ke tahap pembuatan soal.",
    identitySection: "Identitas Ujian",
    examTitle: "Judul Ujian",
    selectSubject: "Pilih Mata Pelajaran",
    descriptionLabel: "Deskripsi (Opsional)",
    scheduleSection: "Jadwal & Waktu",
    examDate: "Tanggal Pelaksanaan",
    examTime: "Waktu Mulai",
    examDuration: "Durasi Ujian",
    securitySection: "Keamanan & Pengaturan",
    randomizeQuestions: "Randomize Soal",
    randomizeSub: "Urutan soal akan diacak untuk setiap siswa.",
    antiCheatLabel: "Aktifkan Anti-Cheat",
    antiCheatSub: "Mencegah siswa berpindah tab atau aplikasi saat ujian.",
    btnProceedQuestions: "Lanjut ke Tambah Soal",
    editQuestionTitle: "Edit Soal / Pertanyaan",
    questionText: "Isi Teks Pertanyaan",
    questionImage: "Gambar Bantuan (Opsional)",
    btnUploadImg: "Unggah Gambar",
    answerChoicesLabel: "Pilihan Jawaban",
    answerChoicesSub: "Isi pilihan jawaban dan pilih tombol bulat untuk jawaban yang benar.",
    saveQuestionBtn: "Simpan Soal / Save Question",
    addAnotherQBtn: "Tambah Soal Lagi / Add Another Question",
    adminTitle: "Halo, Administrator",
    adminSub: "Berikut adalah ringkasan performa akademik hari ini.",
    totalTeachers: "Total Guru",
    activeExamsNum: "Ujian Aktif",
    weeklyActivity: "Aktivitas Mingguan",
    recentExams: "Ujian Terbaru",
    academicGuaranteed: "Academic Integrity Guaranteed",
    cheatingDetected: "PERINGATAN SEKURITI: Anda terdeteksi memindahkan layar atau tab!",
    cheatingExclusion: "Sesi ujian dibatalkan atau terkunci karena aktivitas mencurigakan. Hubungi Administrator!"
  },
  en: {
    tagline: "Secure & Fair Online Exams",
    taglineSub: "Ujian Online ne'ebé Seguru & Justu",
    systemTitle: "Trusted Academic Exam System",
    btnSubmitLogin: "Sign In",
    btnSubmitRegister: "Register Account",
    emailPlaceholder: "name@email.com",
    passwordPlaceholder: "••••••••",
    forgotPass: "Forgot Password?",
    orContinueWith: "Or continue with",
    googleAccount: "Google Account",
    noAccount: "Don't have an account?",
    haveAccount: "Already have an account?",
    fullname: "Full Name",
    roleLabel: "Select Role",
    roleGuru: "Teacher",
    roleMurid: "Student",
    roleAdmin: "Administrator",
    welcomeTitle: "Greetings",
    welcomeSubtitle: "Prepare yourself to achieve the best results today.",
    upcomingBadge: "Next Exam",
    studyStats: "Study Statistics",
    examsCompleted: "Exams Finished",
    avgScore: "Average Score",
    studyMinutes: "Study Minutes",
    ongoingTitle: "Ongoing Examinations",
    btnStartExam: "Start Now",
    examHistory: "Exam History",
    seeAll: "See All",
    thSubject: "Subject Name",
    thDate: "Date Completed",
    thScore: "Score",
    thStatus: "Status",
    navHome: "Home",
    navExams: "Exams",
    navHistory: "History",
    navProfile: "Profile",
    flagBtn: "Flag",
    timeRemaining: "Remaining",
    pointsWeight: "Points/Weight",
    prevBtn: "Previous",
    nextBtn: "Next",
    autoSaved: "Answer saved automatically",
    submitConfirm: "Are you sure you want to end this exam? Ensure all answers have been checked.",
    submittingStatus: "Uploading your answers...",
    langSettings: "Language Settings",
    darkMode: "Dark Mode",
    notifSettings: "Notifications & Security",
    notifExams: "Exam Alerts",
    notifExamsSub: "Alerts for schedules & results",
    changePass: "Change Password",
    verifyAccount: "Verify Account",
    supportHelp: "Help Center",
    termsCond: "Terms & Conditions",
    logoutBtn: "Log Out of App",
    examCompletedBadge: "EXAM FINISHED",
    congratsTitle: "Outstanding",
    congratsSubtitle: "You have completed this exam.",
    reviewPerformance: "Performance Summary",
    accuracy: "Answer Accuracy",
    timeManagement: "Time Management",
    btnReview: "Review Answers",
    btnCertificate: "Certificate",
    timeSpent: "Time Spent",
    rankClass: "Class Rank",
    qListTitle: "Question List",
    correctLabel: "Correct",
    wrongLabel: "Wrong",
    showMore: "Show More Items",
    backToDashboard: "Back to Dashboard",
    teacherWelcome: "Welcome Back, Ms. Sarah",
    teacherSub: "Ready to monitor student academic progress today?",
    totalExams: "Total Exams",
    totalStudents: "Total Students",
    needReview: "Need Review",
    activeExamsToday: "Active Exams Today",
    studentAttendance: "Student Attendance",
    monitorLive: "Monitor Live",
    schedulePlaceholder: "Schedule Another Exam",
    btnCreateExam: "+ Create New Exam",
    breadcrumbDashboard: "Dashboard",
    breadcrumbNewExam: "Create New Exam",
    configNewExam: "Configure New Exam",
    configSub: "Complete the exam details to proceed to question additions.",
    identitySection: "Exam Identity",
    examTitle: "Exam Title",
    selectSubject: "Select Subject",
    descriptionLabel: "Description (Optional)",
    scheduleSection: "Schedule & Timing",
    examDate: "Scheduled Date",
    examTime: "Start Time",
    examDuration: "Exam Duration",
    securitySection: "Security & Settings",
    randomizeQuestions: "Randomize Questions",
    randomizeSub: "Question order will be shuffled for each student.",
    antiCheatLabel: "Enable Anti-Cheat",
    antiCheatSub: "Prevent students from switching tabs or apps.",
    btnProceedQuestions: "Proceed to Add Questions",
    editQuestionTitle: "Edit Question Content",
    questionText: "Question Tectonic Text",
    questionImage: "Illustrative Image (Optional)",
    btnUploadImg: "Upload Image",
    answerChoicesLabel: "Answer Choices",
    answerChoicesSub: "Fill choices and select the radio button for the correct answer.",
    saveQuestionBtn: "Save Question Struct",
    addAnotherQBtn: "Add Another Question Structure",
    adminTitle: "Welcome, Administrator",
    adminSub: "Here is the summary of academic performance today.",
    totalTeachers: "Total Teachers",
    activeExamsNum: "Active Exams",
    weeklyActivity: "Weekly Activity",
    recentExams: "Recent Exams",
    academicGuaranteed: "Academic Integrity Guaranteed",
    cheatingDetected: "SECURITY WARNING: Tab switching or screen blurring detected!",
    cheatingExclusion: "Exam session is canceled or locked due to suspicious background activity. Please contact Administrator!"
  },
  tt: {
    tagline: "Ezame Online Seguru & Justu",
    taglineSub: "Ezame Online ne'ebé Seguru & Justu",
    systemTitle: "Sistema Ezame Akadémiku Konfiável",
    btnSubmitLogin: "Tama",
    btnSubmitRegister: "Repusta Konta",
    emailPlaceholder: "naran@email.com",
    passwordPlaceholder: "••••••••",
    forgotPass: "Haluha Password?",
    orContinueWith: "Ka kontinua ho",
    googleAccount: "Konta Google",
    noAccount: "Seidauk iha konta?",
    haveAccount: "Iha tiha ona konta?",
    fullname: "Naran Kompletu",
    roleLabel: "Hili Kargu",
    roleGuru: "Professor",
    roleMurid: "Estudante",
    roleAdmin: "Admin",
    welcomeTitle: "Bondia",
    welcomeSubtitle: "Prepara ó-nia an atu hetan rezultadu di'ak liu ohin.",
    upcomingBadge: "Ezame Tuirmai",
    studyStats: "Estadístika Estuda",
    examsCompleted: "Ezame Remata",
    avgScore: "Valór Médio",
    studyMinutes: "Minutu Estuda",
    ongoingTitle: "Ezame Ativu daudaun",
    btnStartExam: "Komesa Agora",
    examHistory: "Ezame Pasadu",
    seeAll: "Haree Hotu",
    thSubject: "Naran Materia",
    thDate: "Data Remata",
    thScore: "Valór",
    thStatus: "Estadu",
    navHome: "Uluk",
    navExams: "Ezame",
    navHistory: "Istóriku",
    navProfile: "Perfil",
    flagBtn: "Sinal",
    timeRemaining: "Hela",
    pointsWeight: "Pontu",
    prevBtn: "Uluk",
    nextBtn: "Tuirmai",
    autoSaved: "Resposta rai automatikamente",
    submitConfirm: "Ó fiar katak atu submete ezame ne'e? Asegura resposta hotu korta tiha ona.",
    submittingStatus: "Submete hela resposta...",
    langSettings: "Lian / Language",
    darkMode: "Modu Nakukun",
    notifSettings: "Notifikasaun & Seguransa",
    notifExams: "Notifikasaun Ezame",
    notifExamsSub: "Avizu oráriu & rezultadu",
    changePass: "Troka Password",
    verifyAccount: "Verifikasaun Konta",
    supportHelp: "Ajuda",
    termsCond: "Termu & Kondisaun",
    logoutBtn: "Sai husi Aplicativo",
    examCompletedBadge: "EZAME REMATA",
    congratsTitle: "Kapás Tebes",
    congratsSubtitle: "Ó hotu tiha ona ezame ne'e.",
    reviewPerformance: "Sumáriu Dezempeñu",
    accuracy: "Akurasaun Resposta",
    timeManagement: "Kuidado Tempu",
    btnReview: "Haree Resposta",
    btnCertificate: "Sertifikadu",
    timeSpent: "Tempu Serbi",
    rankClass: "Klasifikasaun Jeral",
    qListTitle: "Lista Pergunta",
    correctLabel: "Loos",
    wrongLabel: "Sala",
    showMore: "Harek barak liu",
    backToDashboard: "Fila fali ba Dashboard",
    teacherWelcome: "Benvinda, Ibu Sarah",
    teacherSub: "Prontu atu hare dezempeñu estudante sira ohin?",
    totalExams: "Ezame Hotu",
    totalStudents: "Estudante Hotu",
    needReview: "Presiza Review",
    activeExamsToday: "Ezame Ativu Ohin",
    studentAttendance: "Prezensa Estudante",
    monitorLive: "Haree Direta",
    schedulePlaceholder: "Agenda Ezame Seluk",
    btnCreateExam: "+ Kria Ezame Foun",
    breadcrumbDashboard: "Dashboard",
    breadcrumbNewExam: "Kria Ezame Foun",
    configNewExam: "Konfigura Ezame Foun",
    configSub: "Prenxe detalla ezame atu kontinua tau pergunta.",
    identitySection: "Identidade Ezame",
    examTitle: "Títulu Ezame",
    selectSubject: "Hili Matéria",
    descriptionLabel: "Deskrisaun (Opsionál)",
    scheduleSection: "Oráriu & Tempu",
    examDate: "Data Ezame",
    examTime: "Tempu Komesa",
    examDuration: "Ezame nia Tempu",
    securitySection: "Seguransa & Konfigurasaun",
    randomizeQuestions: "Hamasak Pergunta",
    randomizeSub: "Selekusaun pergunta sei hamosak ba estudante hotu.",
    antiCheatLabel: "Ativa Anti-Cheat",
    antiCheatSub: "Estudante sira labele troka tab ka aplicativo durante ezame.",
    btnProceedQuestions: "Kontinua ba Pergunta",
    editQuestionTitle: "Kria / Troka Pergunta",
    textQuestion: "Test Pergunta",
    questionImage: "Imajen (Opsionál)",
    btnUploadImg: "Tau Imajen",
    answerChoicesLabel: "OPSION sira",
    answerChoicesSub: "Prenxe resposta no hili botia lo'os.",
    saveQuestionBtn: "Rai Pergunta",
    addAnotherQBtn: "Aumenta Pergunta Seluk",
    adminTitle: "Olá, Administrador",
    adminSub: "Ne'e mak dezempeñu akadémiku ohin nian.",
    totalTeachers: "Professor sira",
    activeExamsNum: "Ezame Ativu",
    weeklyActivity: "Aktividade Semanál",
    recentExams: "Ezame Foun",
    academicGuaranteed: "Academic Integrity Guaranteed",
    cheatingDetected: "ATENSAUN SEGURANSA: Ó troka hela tab ka screen!",
    cheatingExclusion: "Sesaun ezame kansela tiha ona tanba halo atividade ruma suspeitu. Kontakta Admin!"
  }
};

// Seed initial exams
export const INITIAL_EXAMS: Exam[] = [
  {
    id: 'exam-1',
    title: 'Matematika Wajib: Kalkulus II',
    subject: 'Matematika',
    description: 'Ujian mengenai pemahaman turunan, integral lipat dua, dan aplikasi kalkulus dalam geometri ruang.',
    duration: 120,
    randomize: true,
    antiCheat: true,
    status: 'wait',
    scheduledDate: '2024-05-24',
    scheduledTime: '08:00',
    studentCount: '0/32',
    questions: [
      {
        id: 'q1-1',
        text: "Jika sebuah fungsi f(x) = 2x² - 3x + 5, berapakah nilai turunan pertama f'(x) ketika x = 2?",
        points: 5,
        image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBfZnDozVMt8CRtLbxqfvwgm3Bp9bUB5w33CGc_TdjX8LKms6yoi-2kNW2vCtGrjE3GvYvy88so38zfDf4uIub3LmEhSujKq7IhY7HpVF_4O1z9XxsvNdt5S55hjwGIDBEXdLas0U9nLLe13LDMzwJLW6EZyCB83jW80dKVzR44BetDfJXZU8WoZE3kz1lh1gLlPcq18slNu4HtWd-gfz4odUESsgDQwHUhRd_U1O44FLf9P-eJEosrFMB0n_F_yA1fYI3iAoVlJA",
        options: [
          { key: 'A', text: "f'(2) = 5" },
          { key: 'B', text: "f'(2) = 7" },
          { key: 'C', text: "f'(2) = 8" },
          { key: 'D', text: "f'(2) = 11" }
        ],
        correctAnswer: 'B'
      },
      {
        id: 'q1-2',
        text: "Berapakah hasil integral dari ∫ (3x² - 4x + 2) dx?",
        points: 5,
        options: [
          { key: 'A', text: "x³ - 2x² + 2x + C" },
          { key: 'B', text: "3x³ - 4x² + 2x + C" },
          { key: 'C', text: "x³ - 4x² + 2x + C" },
          { key: 'D', text: "3x³ - 2x² + x + C" }
        ],
        correctAnswer: 'A'
      },
      {
        id: 'q1-3',
        text: "Fungsi f(x) = x³ - 3x² mencapai titik stasioner (maksimum/minimum) di x = ...",
        points: 5,
        options: [
          { key: 'A', text: "x = 0 dan x = 1" },
          { key: 'B', text: "x = 0 dan x = 2" },
          { key: 'C', text: "x = 1 dan x = -1" },
          { key: 'D', text: "x = 1 dan x = 2" }
        ],
        correctAnswer: 'B'
      }
    ]
  },
  {
    id: 'exam-2',
    title: 'Reading Comprehension & Grammar',
    subject: 'B. Inggris - Latihan 04',
    description: 'Latihan penguasaan kosa kata bahasa Inggris, pemahaman wacana, dan tata bahasa pasif harian.',
    duration: 45,
    randomize: false,
    antiCheat: true,
    status: 'ongoing',
    scheduledDate: '2026-05-28',
    scheduledTime: '08:00',
    studentCount: '12/32',
    questions: [
      {
        id: 'q2-1',
        text: "Select the grammatical passive voice of: 'The chef prepares a special dinner.'",
        points: 10,
        options: [
          { key: 'A', text: "A special dinner is prepared by the chef." },
          { key: 'B', text: "A special dinner was prepares by the chef." },
          { key: 'C', text: "The chef is preparing a special dinner." },
          { key: 'D', text: "Dinner is prepared nicely." }
        ],
        correctAnswer: 'A'
      },
      {
        id: 'q2-2',
        text: "What is the synonym of the word 'Reluctant' in reading terms?",
        points: 5,
        options: [
          { key: 'A', text: "Eager" },
          { key: 'B', text: "Hesitant" },
          { key: 'C', text: "Happy" },
          { key: 'D', text: "Determined" }
        ],
        correctAnswer: 'B'
      }
    ]
  },
  {
    id: 'exam-3',
    title: 'Kuis Harian: Fotosintesis',
    subject: 'Biologi',
    description: 'Kuis sederhana mengenai reaksi terang, reaksi gelap, kloroplas dan metabolisme sel tumbuhan.',
    duration: 60,
    randomize: true,
    antiCheat: false,
    status: 'ongoing',
    scheduledDate: '2026-05-28',
    scheduledTime: '11:00',
    studentCount: '12/32',
    questions: [
      {
        id: 'q3-1',
        text: "Klorofil pada tumbuhan hijau berperan aktif dalam menyerap cahaya matahari pada panjang gelombang ...",
        points: 5,
        options: [
          { key: 'A', text: "Hijau dan kuning" },
          { key: 'B', text: "Merah dan biru" },
          { key: 'C', text: "Inframerah" },
          { key: 'D', text: "Ultraviolet saja" }
        ],
        correctAnswer: 'B'
      }
    ]
  },
  {
    id: 'exam-4',
    title: 'Ujian Tengah Semester - Aljabar',
    subject: 'Matematika',
    description: 'Ujian aljabar linier meliputi operasi matriks, vektor, nilai eigen, dan sistem persamaan linier.',
    duration: 120,
    randomize: true,
    antiCheat: true,
    status: 'done',
    scheduledDate: '2026-05-27',
    scheduledTime: '08:00',
    studentCount: '32/32',
    questions: []
  }
];

// Initial mock exam history for Budi/Andi
export const INITIAL_HISTORY: ExamHistoryItem[] = [
  {
    id: 'hist-1',
    subject: 'Bahasa Indonesia',
    title: 'Menulis Karya Ilmiah & Sastra',
    date: '18 Mei 2024',
    score: 92,
    maxScore: 100,
    status: 'Lulus'
  },
  {
    id: 'hist-2',
    subject: 'Fisika - Mekanika Quantum',
    title: 'Pengenalan Partikel dan Atom',
    date: '15 Mei 2024',
    score: 78,
    maxScore: 100,
    status: 'Lulus'
  },
  {
    id: 'hist-3',
    subject: 'Sejarah Indonesia',
    title: 'Peradaban Kerajaan Maritim Nusantara',
    date: '10 Mei 2024',
    score: 55,
    maxScore: 100,
    status: 'Remedial'
  }
];
