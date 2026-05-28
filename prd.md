# PRD - Testora

**Product Name:** Testora  
**Version:** 1.0  
**Date:** 28 Mei 2026  
**Platform:** Flutter (Mobile - Android & iOS)

---

## 1. Overview

**Testora** adalah aplikasi **Ujian Online** yang aman dan terstruktur untuk sekolah atau lembaga pendidikan di Timor-Leste. Aplikasi ini mendukung tiga role utama: **Admin**, **Guru**, dan **Murid**.

Aplikasi ini **multi-language**, mendukung **Bahasa Inggris (English)** dan **Bahasa Tetun**.

---

## 2. Objectives

- Menyediakan sistem ujian online yang modern, aman, dan mudah digunakan.
- Mendukung pengguna lokal dengan dukungan bahasa Tetun dan Inggris.
- Fokus pada fungsi inti (MVP) agar aplikasi bisa segera digunakan.

---

## 3. User Roles & Permissions

### 3.1 Admin
- Mengelola semua pengguna (Guru & Murid)
- Melihat overview semua ujian

### 3.2 Guru
- Membuat ujian dan soal
- Menjadwalkan dan menugaskan ujian
- Melihat hasil ujian

### 3.3 Murid
- Mengikuti ujian sesuai jadwal
- Melihat hasil ujian

---

## 4. MVP - Phase 1 (Must Have)

### 4.1 Authentication
- Halaman Login & Register dalam satu screen
- Pilih role saat register (Guru / Murid)
- Admin dibuat manual melalui Firebase

### 4.2 Guru Features (MVP)
- Membuat Ujian Baru (judul, mata pelajaran, tanggal & waktu, durasi)
- Tambah Soal Multiple Choice
- Randomisasi urutan soal
- Penugasan ujian ke murid individu
- Melihat daftar hasil ujian + export CSV

### 4.3 Murid Features (MVP)
- Halaman "Ujian Saya" (Upcoming, Ongoing, Completed)
- Mengerjakan ujian dengan timer
- Auto-submit saat waktu habis
- Melihat nilai setelah ujian selesai

### 4.4 Anti-Cheat (MVP - Prioritas Tinggi)
- Full Screen Lock Mode
- Deteksi keluar aplikasi (App Switch)
- Peringatan + log jika keluar aplikasi
- Auto-submit jika terdeteksi curang

### 4.5 Dashboard
- Dashboard berbeda berdasarkan role

---

## 5. Phase 2 (Nice to Have)

- Tipe soal Essay
- Ujian berbasis Kelas
- Live Monitoring oleh Guru
- Notifikasi Push sebelum ujian
- Analisis statistik soal (tingkat kesulitan)
- Upload gambar pada soal
- Deteksi screenshot

---

## 6. Phase 3 (Advanced)

- Face detection / proctoring
- Randomisasi pilihan jawaban
- Pembahasan jawaban otomatis
- Laporan lengkap dan grafik

---

## 7. Non-Functional Requirements

- **Framework**: Flutter
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore)
- **Design**: Modern, clean, dan fokus untuk ujian

---

## 8. Data Model (Firestore)

```dart
- users (collection)
- exams (collection)
- questions (subcollection)
- exam_assignments (collection)
- exam_logs (anti-cheat)

9. Acceptance Criteria (MVP)

User bisa register & login sesuai role
Guru bisa buat ujian, tambah soal, assign murid
Murid bisa mengerjakan ujian dengan anti-cheat
Soal di-random tiap murid
Guru bisa lihat hasil ujian