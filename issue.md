# Testora - Perencanaan Lengkap Aplikasi Ujian Online (Versi 1.0 MVP)

**Nama Aplikasi**: Testora  
**Bahasa Utama Aplikasi**: **Tetun** (Semua teks, button, error message, dll harus dalam bahasa Tetun)  
**Platform**: Flutter Mobile (Android & iOS)  
**Backend**: Firebase  
**Target**: Timor-Leste (Estudante Eskola, Universidade)

---

## 0. Setup Repository (GitHub) & Issue Tracker

Karena GitHub CLI (`gh`) dan GitHub Desktop sudah terinstall, lakukan langkah ini HANYA SEKALI di awal proyek:

### 0.1 Inisialisasi Git & GitHub Repo (Jalankan di Terminal)
```bash
# 1. Buat project flutter baru
flutter create testora --org com.testora.app
cd testora

# 2. Inisialisasi Git & Buat Repository di GitHub
git init
gh repo create testora --public --source=. --remote=origin

# 3. Pastikan file issue.md dan README.md dipindah ke dalam folder testora.
# Buat Issue di GitHub langsung dari file ini:
gh issue create --title "Epic: MVP Development Testora" --body-file issue.md
```
*(Gunakan **GitHub Desktop** selanjutnya untuk melakukan Commit & Push setiap kali menyelesaikan satu Fase pekerjaan di bawah).*

---

## 1. Project Overview & Setup Awal

Karena FlutterFire CLI dan Firebase CLI sudah terinstall di komputer ini, lanjutkan inisialisasi di dalam folder `testora`:

### 1.1 Inisialisasi Flutter & Firebase (Jalankan di Terminal `testora`)
```bash

# 2. Login Firebase (Browser akan terbuka, login dengan akun Google pemilik project)
firebase login

# 3. Inisialisasi FlutterFire ke Project yang sudah disiapkan (Ini akan membuat firebase_options.dart)
# Info Project: Project ID (testora-ee95f), Project Number (838087878656)
flutterfire configure --project=testora-ee95f
# (Pilih/pastikan terhubung ke testora-ee95f dan centang platform Android & iOS)

# 4. Install Dependencies Utama
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add dev:riverpod_generator dev:build_runner
flutter pub add go_router
flutter pub add easy_localization
flutter pub add google_fonts
```

### 1.2 Konfigurasi `pubspec.yaml`
Pastikan pada bagian `flutter:` ditambah assets untuk bahasa:
```yaml
flutter:
  assets:
    - assets/lang/
```

---

## 2. Struktur Folder Project Lengkap (Clean Architecture - Feature First)

**Instruksi Penting untuk AI Agent & Junior Dev:** 
Buat folder dan file ini secara bertahap, **JANGAN** dibuat sekaligus dalam satu waktu agar tidak bingung. Fokus kerjakan per fitur (Feature-Driven).

```text
lib/
├── core/
│   ├── constants/             # colors.dart, text_styles.dart
│   ├── localization/          # tetun.json (sebenarnya diletakkan di assets/lang/tetun.json)
│   ├── routes/                # app_router.dart (Konfigurasi GoRouter)
│   ├── themes/                # app_theme.dart
│   ├── utils/                 # formatters.dart, validators.dart
│   └── error/                 # failure.dart, exceptions.dart
│
├── features/
│   ├── auth/                  # Fitur Login / Register
│   │   ├── presentation/      # UI (login_screen.dart, register_screen.dart)
│   │   ├── providers/         # Riverpod providers untuk auth (auth_provider.dart)
│   │   └── repositories/      # auth_repository.dart
│   │
│   ├── exam/                  # Fitur Ujian Utama
│   │   ├── presentation/      # list_exam_screen.dart, take_exam_screen.dart, result_screen.dart
│   │   ├── providers/         # exam_provider.dart, timer_provider.dart
│   │   └── repositories/      # exam_repository.dart
│   │
│   ├── history/               # Riwayat Nilai
│   └── profile/               # Edit Profil & Logout
│
├── shared/
│   ├── models/                # user_model.dart, exam_model.dart, question_model.dart, result_model.dart
│   ├── widgets/               # custom_button.dart, custom_textfield.dart, loading_overlay.dart
│   └── services/              # firebase_service.dart (Opsional jika repository sudah meng-handle langsung)
│
├── firebase_options.dart      # (Digenerate otomatis oleh flutterfire configure)
└── main.dart                  # Entry point (ProviderScope, Firebase.initializeApp & EasyLocalization)
```

---

## 3. Backend Firebase - Detail Lengkap & Skema Database

### 3.1 Setup Awal di `main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Inisialisasi Firebase menggunakan file hasil generate FlutterFire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('tet', 'TL')],
        path: 'assets/lang',
        fallbackLocale: const Locale('tet', 'TL'),
        child: const MyApp(),
      ),
    ),
  );
}
```

### 3.2 Firestore Database Structure (Collections & Documents)

Penting: AI Agent harus membuat model (`.dart`) yang benar-benar cocok dengan struktur ini. Gunakan metode `fromMap` dan `toMap` dengan pengecekan `null` yang ketat.

**1. users** (document ID = uid dari Firebase Auth)
- `name` (String) → "Naran"
- `email` (String)
- `school` (String) → "Eskola / Universidade"
- `role` (String) → "student" atau "admin"
- `createdAt` (Timestamp)

**2. exams** (document ID = auto generated string)
- `title` (String) → "Teste Matematika"
- `description` (String)
- `duration` (int) → durasi dalam menit (contoh: 60)
- `totalQuestions` (int)
- `category` (String)
- `isActive` (bool) → Jika false, ujian tidak muncul di user

**3. exams/{examId}/questions** (Subcollection)
- `questionText` (String)
- `options` (Array<String>) → ["Opisaun A", "Opisaun B", "Opisaun C", "Opisaun D"]
- `correctAnswerIndex` (int) → index dari array options yang benar (0 sampai 3)

**4. user_exam_results** (document ID = auto generated string)
- `userId` (String)
- `examId` (String)
- `score` (int) → jumlah soal yang benar
- `percentage` (double) → persentase nilai (0.0 - 100.0)
- `timeTaken` (int) → durasi waktu yang dihabiskan dalam detik
- `submittedAt` (Timestamp)

### 3.3 Firebase Security Rules (Panduan Setup)
Copy dan paste rules ini ke **Firebase Console > Firestore Database > Rules** setelah project dibuat:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Aturan untuk Users
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Aturan untuk Ujian (Semua user login bisa baca, tidak ada yang bisa nulis dari app student)
    match /exams/{examId} {
      allow read: if request.auth != null;
      allow write: if false; // Data ujian hanya ditambah dari console firebase atau app admin
    }
    // Aturan untuk Soal Ujian
    match /exams/{examId}/questions/{questionId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
    // Aturan untuk Hasil Ujian
    match /user_exam_results/{resultId} {
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 4. Panduan State Management (Riverpod) untuk AI & Junior Dev

Karena project ini dipegang oleh AI Agent / Junior Dev, instruksi Riverpod harus dipecah sangat kecil dan terfokus (jangan menggabungkan semua logika di UI):

1. **Repository Pattern Dulu**: Buat file repository (`auth_repository.dart`, `exam_repository.dart`) yang HANYA berisi fungsi memanggil Firebase (misal `signInWithEmail`, `getExams`). Tangkap error Firebase (FirebaseException) di sini.
2. **Notifier / Provider State**: Buat provider untuk mengatur state UI (Loading, Success, Error). Contoh: `class AuthNotifier extends _$AuthNotifier` (jika pakai riverpod_generator) atau `StateNotifier`.
3. **Timer Logic Pisahkan**: Buat Provider khusus untuk timer ujian. Jangan letakkan `Timer.periodic` di dalam `StatefulWidget`, biarkan Riverpod yang menghitung mundur detik dan UI hanya listen statenya.

---

## 5. UI/UX dan Localization - Bahasa Tetun (Wajib)

### 5.1 Desain dan Tema
- **Warna Utama**: Pilih warna yang rapi, contoh: Primary `Color(0xFF1976D2)` (Biru), Background `Color(0xFFF5F5F5)` (Abu-abu muda).
- **Tipografi**: Gunakan `GoogleFonts.inter()` atau `GoogleFonts.rubik()`.
- **Reusability**: AI **WAJIB** membuat komponen terpisah untuk tombol (`CustomButton`) dan input teks (`CustomTextField`) agar desain konsisten dan kode UI tidak kotor.

### 5.2 File Bahasa (`assets/lang/tetun.json`)
Buat file ini dari awal, karena semua teks wajib berbahasa Tetun:
```json
{
  "app_name": "Testora",
  "login": "Tama",
  "register": "Rejista",
  "email": "Email",
  "password": "Password",
  "start_exam": "Hahú Teste",
  "time_remaining": "Tempu hela",
  "submit": "Entrega",
  "score": "Pontu",
  "history": "Istória",
  "profile": "Perfil",
  "logout": "Sai",
  "error_occurred": "Akontese sala. Favor koko fali.",
  "empty_exam": "Seida'uk iha teste disponivel.",
  "success_submit": "Teste entrega ho susesu!",
  "confirm_submit": "Ita boot hakarak entrega teste ne'e?",
  "yes": "Sin",
  "no": "Lae"
}
```
*Penggunaan di Widget*: `Text('login'.tr())`

---

## 6. Urutan Pengerjaan Step-by-Step (Sangat Penting untuk AI)

AI Agent atau Junior Dev **HARUS** mengeksekusi project ini secara bertahap sesuai urutan berikut. Jangan melompat ke langkah berikutnya sebelum langkah saat ini benar-benar berjalan tanpa error.

- **Fase 1: Setup & Konfigurasi Dasar** 
  (Jalankan flutterfire configure, buat folder struktur, setup pubspec.yaml, setup `main.dart` dengan EasyLocalization dan Riverpod, buat `tetun.json`). Test Run aplikasi sampai muncul layar putih polos tanpa error.
- **Fase 2: Autentikasi (Login & Register)** 
  (Buat `UserModel`, `AuthRepository`, UI Login & Register). Uji coba login menggunakan Firebase Auth, tangani error (misal password salah), pastikan bisa masuk ke halaman utama (Home).
- **Fase 3: List Ujian (Dashboard)** 
  (Buat `ExamModel`, `ExamRepository` untuk get list exam, buat `ListExamScreen`). Karena belum ada fitur admin, buat dokumen ujian dummy langsung dari *Firebase Console*, lalu test apakah data muncul di layar Home.
- **Fase 4: Core Engine - Mengerjakan Ujian (Paling Krusial)** 
  (Buat `QuestionModel`, layar `TakeExamScreen`). Di fase ini, bangun Timer mundur, simpan jawaban sementara di memory (Map state Riverpod), dan buat tombol Next/Prev (atau Scroll list panjang).
- **Fase 5: Kalkulasi Hasil & Riwayat** 
  (Buat tombol Submit, hitung jumlah benar/salah, kirim data result ke subcollection `user_exam_results`. Buat `ResultScreen` untuk menampilkan nilai, dan `HistoryScreen` untuk melihat riwayat).

---

## 7. Aturan Ketat untuk Mencegah Bug (Safety Rules)

1. **Null Safety Firestore**: Saat melakukan parsing data dari Firebase Firestore ke Model Dart (misal di fungsi `factory ExamModel.fromMap(Map<String, dynamic> map)`), **SELALU** berikan default value. Jangan pernah asumsikan field selalu ada. 
   *(Contoh: `title: map['title'] ?? 'Ujian Tanpa Judul'`)*.
2. **Dispose Timer Ujian**: Pada layar Ujian (`TakeExamScreen`), pastikan timer benar-benar di-cancel/dispose saat user selesai ujian atau aplikasi tertutup tiba-tiba.
3. **Kunci Tombol Back**: Saat user sedang mengerjakan ujian (berada di `TakeExamScreen`), blokir tombol Back bawaan Android menggunakan widget `PopScope` agar user tidak tidak sengaja keluar dan kehilangan pekerjaannya.
4. **Loading States**: Jangan biarkan layar freeze saat koneksi ke Firebase lambat. AI harus menambahkan indikator `CircularProgressIndicator` di setiap aksi (Login, Submit Ujian, Fetch Soal).
5. **No Hardcoded Strings**: Tidak boleh ada `Text("Login")` secara langsung di kodingan. Semua harus `Text("login".tr())`.

---

**Dokumen Siap Dieksekusi!**
Mulai dari **Fase 1**. Jangan lanjutkan ke Fase 2 sebelum Fase 1 berhasil di-build!
