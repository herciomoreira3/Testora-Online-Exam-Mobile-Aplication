# Frontend Design Prompt for Testora - Detailed Version

Kamu adalah **Senior UI/UX Designer** yang sangat berpengalaman dalam membangun aplikasi mobile Flutter dengan standar tinggi. Buatlah desain UI/UX yang modern, clean, profesional, edukatif, dan mudah digunakan untuk aplikasi **Testora** - Aplikasi Ujian Online.

### Brand Identity & Design System
- **Primary Color**: #1E40AF (Deep Blue)
- **Accent Color**: #10B981 (Emerald Green)
- **Secondary Color**: #3B82F6 (Light Blue)
- **Background**: #F8FAFC (Light) & #0F172A (Dark)
- **Text Color**: #1E2937 (Dark) & #F1F5F9 (Light)
- **Typography**: Poppins (Heading) & Inter (Body)
- **Corner Radius**: 16px (medium), 24px (large cards)
- **Shadow**: Soft neumorphic shadow
- **Style**: Modern Minimalist dengan sentuhan edukasi

**Multi-Language**: Aplikasi harus mendukung **English** dan **Tetun**. Semua teks harus menggunakan localization keys. Layout harus fleksibel (RTL/LTR support jika diperlukan).

---

## Daftar Screen yang Harus Dirancang Secara Detail

### 1. Splash Screen
- Full screen dengan gradient background (Deep Blue ke Light Blue)
- Logo Testora besar di tengah
- Tagline: "Ujian Online yang Aman & Adil" (EN) / "Ujian Online ne'ebé Seguru & Justu" (Tetun)
- Loading indicator halus di bawah

### 2. Onboarding / Login & Register Screen
- Background dengan subtle pattern edukasi
- Tab Switcher: Login | Register (animated)
- Input fields: Nama Lengkap, Email, Password, Konfirmasi Password
- Dropdown Role: Guru / Murid (dengan icon)
- Tombol utama besar dengan accent color
- Link "Lupa Password?" dan "Belum punya akun?"
- Social login (Google) opsional di bawah

### 3. Dashboard Screens (3 Versi)

**A. Dashboard Admin**
- AppBar dengan logo kecil + nama sekolah
- 4 Statistik Cards (Total Guru, Total Murid, Total Ujian, Ujian Aktif Hari Ini)
- Chart sederhana mingguan
- List "Ujian Terbaru"
- Bottom Navigation Bar (5 item): Home, Users, Exams, Reports, Profile

**B. Dashboard Guru**
- Header dengan sapaan "Selamat Datang, [Nama]" 
- Card "Ujian Aktif Hari Ini"
- Quick Action Floating Button besar: "+ Buat Ujian Baru"
- Statistik horizontal scroll
- Bottom Navigation: Home, My Exams, Students, Results, Profile

**C. Dashboard Murid**
- Header dengan foto profil + nama murid
- Card besar "Ujian Selanjutnya" dengan countdown timer
- Section "Ujian Sedang Berlangsung"
- Section "Riwayat Ujian"
- Bottom Navigation: Home, My Exams, History, Profile

### 4. Exam Taking Screen (Paling Penting - Full Screen)
- **Full Screen Lock Mode** (hide system bar jika memungkinkan)
- Header tetap: Nama Ujian + Timer Besar (merah jika < 10 menit)
- Progress Bar di bawah header
- Nomor Soal (1 dari 20)
- Pertanyaan dengan ukuran font besar
- Opsi jawaban dalam Card (4 pilihan)
- Tombol navigasi: Sebelumnya | Selanjutnya | Tandai
- Floating Submit Button
- Desain sangat minimalis, anti-distraksi

### 5. Create New Exam Screen (Guru)
- Form dengan sections yang jelas
- Input: Judul Ujian, Mata Pelajaran, Deskripsi
- Date & Time Picker
- Duration Slider
- Switch: Randomize Soal
- Switch: Aktifkan Anti-Cheat
- Tombol "Lanjut ke Tambah Soal"

### 6. Add / Edit Question Screen
- Textarea besar untuk pertanyaan
- 4 input field untuk opsi jawaban (dengan radio button untuk jawaban benar)
- Input bobot nilai
- Upload gambar soal (opsional)
- Tombol "Simpan Soal" & "Tambah Soal Lagi"

### 7. Exam Assignment & Scheduling Screen
- Searchable list murid
- Multi-select murid atau pilih kelas
- Date & Time picker
- Ringkasan assignment

### 8. Live Monitoring Screen (Guru)
- Real-time list murid yang sedang ujian
- Progress circle per murid
- Status (Online / Warning / Finished)
- Search & Filter

### 9. Exam Result Screen
- Nilai akhir sangat besar dan menonjol
- Persentase benar/salah
- List soal dengan highlight jawaban benar & salah
- Tombol "Lihat Pembahasan" & "Download Sertifikat"

### 10. Profile & Settings Screen
- Foto profil + nama + role
- Pengaturan Bahasa (English / Tetun) dengan flag
- Dark Mode toggle
- Notifikasi settings
- Logout button

---

**Design Requirements Tambahan:**
- Gunakan Material 3 Design System
- Semua screen harus responsif dan nyaman di tangan
- Animasi halus (fade, slide, scale)
- Consistent icon set (gunakan Icons dari Material atau custom)
- Status badge dengan warna berbeda: Upcoming (Orange), Ongoing (Blue), Completed (Green), Late (Red)
- Error state dan Empty state yang baik
- Loading skeletons

Buatlah deskripsi desain yang **sangat detail** untuk setiap screen di atas, termasuk:
- Layout structure (AppBar, Body, Bottom Bar)
- Warna dan tipografi yang digunakan
- Komponen Flutter yang disarankan
- User flow antar screen
- Cara menangani multi-language

Output dalam format yang rapi, terstruktur, dan siap digunakan untuk pengembangan.