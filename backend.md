# Backend Documentation - Testora

**Product Name:** Testora  
**Version:** 1.0  
**Date:** 28 Mei 2026  

---

## 1. Overview

**Testora** adalah aplikasi Ujian Online yang menggunakan **Firebase** sebagai backend utama dengan pendekatan **gratis** sebanyak mungkin. 

**Kebijakan Penting:**
- Tidak menggunakan **Firebase Cloud Functions** (karena berbayar setelah quota gratis habis).
- Notifikasi Push menggunakan **OneSignal** (gratis).
- Semua logic sebisa mungkin dilakukan di client-side (Flutter) dengan keamanan melalui **Firebase Security Rules**.

---

## 2. Technology Stack

| Komponen              | Teknologi                          | Keterangan                     |
|-----------------------|------------------------------------|--------------------------------|
| Authentication        | Firebase Authentication            | Email/Password + Google        |
| Database              | Firebase Firestore                 | NoSQL Database                 |
| File Storage          | Firebase Storage                   | Untuk gambar soal & dokumen    |
| Push Notification     | OneSignal                          | Gratis & mudah integrasi       |
| State Management      | Riverpod                           | Frontend                       |
| Hosting (jika perlu)  | Firebase Hosting                   | Untuk web version (opsional)   |
| Analytics             | Firebase Analytics                 | Gratis                         |

---

## 3. Firebase Project Setup

- Project Name: `testora-app`
- Location: `asia-southeast2` (singapore) - lebih dekat dengan Timor-Leste
- Enable:
  - Authentication (Email/Password)
  - Firestore Database
  - Storage
  - Analytics

---

## 4. Data Model (Firestore)

```dart
Collection: users
  - uid (string)
  - name (string)
  - email (string)
  - role (string) → "admin" | "teacher" | "student"
  - language (string) → "en" | "tet"
  - createdAt (timestamp)
  - photoUrl (string)
  - isActive (boolean)

Collection: classes (untuk Phase 2)
  - id
  - name (Kelas 7A, dll)
  - teacherId

Collection: exams
  - id
  - title
  - subject
  - description
  - teacherId
  - startTime (timestamp)
  - endTime (timestamp)
  - duration (int) → menit
  - shuffleQuestions (boolean)
  - antiCheatEnabled (boolean)
  - totalQuestions (int)
  - createdAt

Subcollection: exams/{examId}/questions
  - id
  - text
  - options (array)
  - correctAnswer (string/index)
  - point (int)
  - imageUrl (string, opsional)

Collection: exam_assignments
  - id
  - examId
  - studentId
  - status → "assigned" | "in_progress" | "submitted" | "late"
  - score (double)
  - submittedAt (timestamp)
  - startedAt (timestamp)

Collection: exam_logs (Anti-Cheat)
  - id
  - examId
  - studentId
  - action (string) → "app_minimized", "screenshot", "disconnected", dll
  - timestamp
  - details

5. Authentication Flow

User register/login melalui Flutter
Saat register, user memilih role (teacher/student)
Admin dibuat manual di Firebase Console
Set custom claims jika diperlukan (tapi minim karena tanpa Cloud Functions)


6. Push Notification (OneSignal)
Alasan memilih OneSignal:

Gratis hingga ribuan user
Mudah integrasi dengan Flutter
Bisa kirim notifikasi dari client-side

Implementasi:

Install package onesignal_flutter
Set OneSignal App ID di Firebase Remote Config atau di code
Kirim notifikasi dari Flutter client (dengan batasan permission)
Template notifikasi:
Pengingat ujian (30 menit sebelum)
Ujian sudah dimulai
Hasil ujian sudah keluar


Catatan: Karena tidak ada Cloud Functions, notifikasi reminder akan dikirim dari device Guru/Admin atau menggunakan cron job eksternal gratis (seperti GitHub Actions atau external service gratis).

7. Security Rules (Firestore)
Security Rules sangat penting karena tidak ada Cloud Functions.
JavaScriptrules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || 
                   get(/databases/$$   (database)/documents/users/   $$(request.auth.uid)).data.role == 'admin';
    }

    // Exams
    match /exams/{examId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
                                  get(/databases/$$   (database)/documents/users/   $$(request.auth.uid)).data.role == 'teacher';
    }

    // Exam Assignments
    match /exam_assignments/{assignmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                   (request.auth.uid == resource.data.studentId || 
                    get(/databases/$$   (database)/documents/users/   $$(request.auth.uid)).data.role in ['teacher', 'admin']);
    }
  }
}

8. Anti-Cheat Implementation (Client Side)
Karena tidak ada Cloud Functions:

Full Screen Detection
App Lifecycle Observer (detect paused/resumed)
Screenshot detection (menggunakan package)
Semua log dikirim langsung ke Firestore collection exam_logs
Guru bisa melihat log di halaman monitoring


9. Limitations (Tanpa Cloud Functions)

Tidak ada server-side validation kompleks
Reminder notifikasi harus dikirim manual atau dari client
Tidak ada otomatisasi berat (contoh: auto close ujian)
Semua logic pengecekan waktu ujian dilakukan di client-side

Solusi alternatif gratis yang bisa digunakan nanti:

GitHub Actions (cron job)
External service gratis (seperti n8n.cloud free tier atau Make.com)


10. Flutter Packages yang Direkomendasikan (Backend Related)

firebase_auth
cloud_firestore
firebase_storage
onesignal_flutter
flutter_local_notifications
intl (untuk multi language)
easy_localization


Prepared by: Grok
Backend Strategy: Firebase + OneSignal (Free Tier Focused)