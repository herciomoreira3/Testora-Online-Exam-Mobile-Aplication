# Testora v2 - Ekspansi Role & Manajemen Ujian In-App (Admin, Professor, Estudante)

**Tujuan**: Mengubah Testora dari sekadar aplikasi klien siswa menjadi platform lengkap (All-in-One) di mana pembuatan soal, manajemen ujian, dan manajemen user dapat dilakukan langsung dari dalam aplikasi mobile tanpa perlu membuka Firebase Console.

**Bahasa Utama UI**: **Tetun**
**Arsitektur**: Feature-First Clean Architecture (melanjutkan struktur v1)
**State Management**: Riverpod (Notifier & NotifierProvider)

---

## 1. Perubahan Struktur Database & Security Rules

### 1.1 Update Model User (`users` collection)
Field `role` pada `UserModel` yang sudah ada akan dipetakan dengan logika 3 jenis role:
- `admin`: Super admin, bisa mengubah role user lain.
- `professores`: Guru/Dosen, bisa membuat ujian, menambah soal, mengelola status ujian, dan melihat nilai siswa.
- `estudante`: Siswa (default saat register), hanya bisa mengerjakan ujian.

### 1.2 Update Model Exam (`exams` collection)
Perlu penyesuaian atau penambahan field untuk melacak kepemilikan ujian:
- `createdBy` (String) -> Menyimpan `uid` dari professor yang membuat ujian. (Opsional untuk MVP jika semua guru saling berbagi ujian, tetapi direkomendasikan agar dashboard guru lebih rapi).
- `createdAt` (Timestamp) -> Waktu ujian dibuat untuk sorting.

### 1.3 Firebase Security Rules (Sangat Penting)
AI Agent/Dev harus memperbarui rules di Firebase Console agar aman dari manipulasi data klien:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fungsi bantuan untuk mengecek role (Wajib 1 read/request tambahan)
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    match /users/{userId} {
      allow read: if request.auth != null;
      // Admin bisa edit role user lain. User biasa hanya bisa edit profilnya sendiri (hindari update role oleh siswa).
      allow update: if request.auth != null && (request.auth.uid == userId || getUserRole() == 'admin');
      allow create: if request.auth != null && request.auth.uid == userId;
    }

    match /exams/{examId} {
      // Semua role bisa baca (siswa butuh baca untuk tes, admin/guru untuk dashboard)
      allow read: if request.auth != null;
      // Hanya professor dan admin yang bisa membuat, mengedit, atau menghapus ujian
      allow write: if request.auth != null && (getUserRole() == 'professores' || getUserRole() == 'admin');
    }

    match /exams/{examId}/questions/{questionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && (getUserRole() == 'professores' || getUserRole() == 'admin');
    }

    match /user_exam_results/{resultId} {
      // Siswa bisa menyimpan hasil.
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
      // Professor/Admin bisa baca semua hasil. Siswa baca hasil miliknya sendiri.
      allow read: if request.auth != null && (resource.data.userId == request.auth.uid || getUserRole() == 'professores' || getUserRole() == 'admin');
    }
  }
}
```

---

## 2. Struktur Folder Tambahan

Tambahkan fitur baru ke dalam folder `lib/features/`:

```text
lib/
├── features/
│   ├── admin/                 # Khusus Role Admin
│   │   ├── presentation/      # admin_dashboard_screen.dart, manage_users_screen.dart
│   │   └── providers/         # admin_provider.dart
│   │
│   ├── professor/             # Khusus Role Professores (Guru)
│   │   ├── presentation/      # prof_dashboard_screen.dart, create_exam_screen.dart, manage_questions_screen.dart, view_results_screen.dart
│   │   └── providers/         # professor_exam_provider.dart
│   │
```

---

## 3. Fase Implementasi (Step-by-Step untuk AI / Junior Dev)

**Instruksi**: Eksekusi per Fase secara berurutan. Pastikan `flutter analyze` berjalan tanpa error sebelum melompat ke fase selanjutnya. Gunakan widget `LoadingOverlay` yang sudah ada untuk menahan UI saat loading.

### Fase 1: Role-Based Routing (Navigasi Berdasarkan Role)
- **Tugas**: Modifikasi `lib/core/routes/app_router.dart` dan `auth_provider.dart`.
- **Logika**: 
  - Saat login berhasil (atau saat aplikasi dibuka dan token valid), baca field `role` dari `UserModel` pengguna tersebut.
  - Jika `role == 'admin'`, arahkan ke rute `/admin-dashboard`.
  - Jika `role == 'professores'`, arahkan ke `/prof-dashboard`.
  - Jika `role == 'estudante'`, arahkan ke `/home` (yang saat ini adalah `ListExamScreen`).
- **Aksi Keamanan**: Di bagian `redirect` GoRouter, pastikan siswa dicegah mereload URL ke dashboard guru.

### Fase 2: Fitur Admin (Manajemen Pengguna)
- **Tugas**: Buat layar `AdminDashboardScreen` dan `ManageUsersScreen`.
- **UI/UX**: 
  - Menampilkan daftar semua pengguna terdaftar dari koleksi `users`.
  - Admin dapat menekan kartu pengguna dan mengubah `role` mereka melalui menu *Dropdown* (Pilih: `estudante`, `professores`, atau `admin`).
- **State Management**: Buat `admin_provider.dart` untuk *fetch* daftar user dan *update* field `role` langsung ke Firestore.

### Fase 3: Fitur Professor - Manajemen Ujian (CRUD Ujian)
- **Tugas**: Buat `ProfDashboardScreen` (Daftar ujian yang dibuat) dan form `CreateExamScreen`.
- **Logika Form**:
  - Input form dengan `CustomTextField`: Títulu Teste (Judul), Deskrisaun, Durasaun (Menit), Kategoria.
  - Saat dikirim (Submit), Firebase meng-generate ID dokumen baru ke koleksi `exams`.
  - Tambahkan fitur **Switch Toggle** "Ativu / La Ativu" (`isActive`) di layar guru, agar ujian bisa disembunyikan sementara dari layar siswa saat soal sedang disusun.

### Fase 4: Fitur Professor - Manajemen Soal (CRUD Soal)
- **Tugas**: Buat layar `ManageQuestionsScreen` yang terbuka saat guru memilih sebuah ujian di dashboardnya.
- **UI/UX**:
  - List kartu pertanyaan yang sudah dibuat, yang diload dari subcollection `/exams/{examId}/questions`.
  - Terdapat FloatingActionButton **"Aumenta Pergunta" (Tambah Soal)**.
- **Form Tambah/Edit Soal**:
  - 1 `TextField` panjang untuk Teks Soal.
  - 4 `TextField` untuk Pilihan Ganda (A, B, C, D).
  - Elemen Radio Button / Dropdown untuk menandai index opsi yang **Benar** (`correctAnswerIndex`: 0, 1, 2, atau 3).
  - Validasi wajib: Tidak boleh ada opsi jawaban yang kosong.

### Fase 5: Fitur Professor - Pantau Hasil Ujian Siswa
- **Tugas**: Buat `ViewResultsScreen`.
- **Logika**:
  - Terdapat tombol "Haree Rezultadu" pada detail ujian di dashboard Guru.
  - Saat dibuka, Riverpod akan me-listen ke koleksi `user_exam_results` dengan filter `.where('examId', isEqualTo: id_ujian_tersebut)`.
  - Membutuhkan query silang (Join) ke koleksi `users` untuk mengambil nama siswa berdasarkan `userId` di dokumen hasil.
  - Tampilkan list siswa, persentase nilai (dengan lencana warna), dan durasi pengerjaannya. Diurutkan dari nilai tertinggi.

---

## 4. Update File Bahasa Tetun (`tetun.json`)

Tambahkan terjemahan kamus ini ke `assets/lang/tetun.json`:

```json
{
  "admin_dashboard": "Painel Administradór",
  "prof_dashboard": "Painel Mestre",
  "manage_users": "Jere Uzuáriu Sira",
  "manage_exams": "Jere Teste Sira",
  "create_exam": "Kria Teste Foun",
  "exam_title": "Títulu Teste",
  "exam_desc": "Deskrisaun Teste",
  "exam_category": "Kategoria Teste",
  "add_question": "Aumenta Pergunta",
  "question_text": "Teks Pergunta",
  "option_a": "Opsaun A",
  "option_b": "Opsaun B",
  "option_c": "Opsaun C",
  "option_d": "Opsaun D",
  "correct_option": "Opsaun ne'ebé Loos",
  "save": "Rai (Save)",
  "delete": "Apaga (Delete)",
  "edit": "Edita",
  "view_results": "Haree Rezultadu Sira",
  "student_name": "Naran Estudante",
  "is_active": "Teste Ativu",
  "change_role": "Muda Papél"
}
```

---

## 5. Aturan Ketat untuk AI / Junior Dev (Safety Rules v2)

1. **Routing Protection**: Pastikan user dengan role `estudante` TIDAK BISA mengakses rute `/admin-dashboard` atau `/prof-dashboard` dengan mem-bypass URL. Terapkan proteksi ketat di `redirect` GoRouter.
2. **Soft Delete Ujian**: Jika Guru ingin "menghapus" ujian, sebaiknya jangan gunakan perintah hapus permanen (`delete()`) dari Firestore, karena itu tidak akan menghapus soal di subcollection dan dapat merusak relasi historis. Cukup update statusnya menjadi `isActive: false` (Soft Delete).
3. **Optimasi Join Data Nama Siswa**: Koleksi hasil ujian (`user_exam_results`) hanya berisi `userId`. AI harus mengurus pemanggilan data nama dari koleksi `users` untuk ditampilkan di dashboard Guru.

**Selesai. Dokumen Siap Dieksekusi mulai dari Fase 1.**
