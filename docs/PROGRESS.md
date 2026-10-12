# Cal Application - Progress Tracker

**Mode Eksekusi:** OTONOM  
**Tanggal Terakhir Diperbarui:** 2026-10-12  
**Fase Saat Ini:** Fase 7 (Selesai & Terverifikasi) → Memulai Fase 8 (Gamifikasi, Komunitas & Notifikasi: F16, F17, F18, F20, F21)  
**Branch Git:** `feat/cal-build`

---

## 1. Matriks Fitur (F00 – F22)

| ID | Fitur | Status | Bukti / Pengujian | Catatan & Keterbatasan |
|:---|:---|:---:|:---|:---|
| **F00** | Fondasi & Arsitektur | TERVERIFIKASI | `flutter test` (4 tests passed), `vitest` (2 tests passed), `flutter analyze` clean | Tema Flutter Emerald/Orange/Indigo, CalMacroColors ThemeExtension, GoRouter 4 tabs, TokenStorage, ApiClient Dio, OfflineQueue UUIDv4 |
| **F01** | Akun, Profil & Target Nutrisi | TERVERIFIKASI | `vitest tests/nutritionCalculator.test.ts` (5 passed), `vitest tests/authAndProfile.test.ts` (11 passed), `flutter test test/auth_flow_test.dart` (3 passed) | Register, login, refresh rotation, age gate >= 18 strict, rumus Mifflin-St Jeor, batas lantai 1200/1500 kkal, override target manual, persistensi PostgreSQL |
| **F02** | Foto Makanan (AI Vision) | TERVERIFIKASI | `vitest tests/ai.test.ts`, `flutter test test/ai_flow_test.dart` | Deteksi makanan vision, pencocokan DB lokal, porsi gram, badge transparan "Estimasi AI", konfirmasi/skala porsi sebelum simpan, fallback non-makanan edukatif |
| **F03** | Barcode Scanner (Open Food Facts) | PERLU-UJI-LIVE | `vitest tests/nutrition.test.ts` (barcode query, fallback to manual entry passed) | Backend caching & lookup OFF ODbL berfungsi; butuh kamera fisik perangkat untuk scan live (tercatat di `docs/MANUAL_TEST.md`) |
| **F04** | Teks Bahasa Sehari-hari | TERVERIFIKASI | `vitest tests/ai.test.ts`, `flutter test test/ai_flow_test.dart` | Parser bahasa Indonesia, ekstraksi kuantitas prefix/postfix, normalisasi takaran lokal (centong, potong, sdm, butir) ke gram, hitung makro & simpan |
| **F05** | Pencarian & Input Manual Makanan | TERVERIFIKASI | `vitest tests/nutrition.test.ts`, `flutter test test/nutrition_flow_test.dart` | Pencarian toleran typo/casing makanan lokal, custom user food item, portion multiplier |
| **F06** | Dashboard & Tracker Harian | TERVERIFIKASI | `vitest tests/nutrition.test.ts`, `flutter test test/nutrition_flow_test.dart` | Total kalori, sisa, target vs konsumsi makro, 4 slot waktu makan, snapshot nilai gizi, auto-recalculate |
| **F07** | Riwayat & Ringkasan Makanan | TERVERIFIKASI | `vitest tests/nutrition.test.ts` | Riwayat harian, edit/hapus item otomatis perbarui total, ringkasan mingguan 7 hari |
| **F08** | AI Nutrition Coach | TERVERIFIKASI | `vitest tests/ai.test.ts`, `flutter test test/ai_flow_test.dart` | Chat context-aware dengan snapshot nutrisi hari ini, batas aman kesehatan, disclaimer medis, rekomendasi makanan lokal |
| **F09** | Resep Sehat Indonesia | TERVERIFIKASI | `vitest tests/recipesAndPlanner.test.ts`, `flutter test test/recipe_planner_flow_test.dart` | 20 resep lokal Indonesia di PostgreSQL, scaling porsi matematis, filter tags, konversi langsung ke meal log |
| **F10** | Menu Harian AI | TERVERIFIKASI | `vitest tests/recipesAndPlanner.test.ts`, `flutter test test/recipe_planner_flow_test.dart` | Generator menu 1-hari seimbang berbasis resep DB dalam batas toleransi kalori (±10%), opsi alternatif per meal slot |
| **F11** | Rencana Harian Terpadu | TERVERIFIKASI | `vitest tests/recipesAndPlanner.test.ts`, `flutter test test/recipe_planner_flow_test.dart` | Dashboard terpadu hari ini menyatukan target nutrisi, hidrasi (+250ml), jadwal gym aktif, menu rekomendasi, dan checklist harian |
| **F12** | Progres Tubuh & Ukuran | TERVERIFIKASI | `vitest tests/workoutsAndProgress.test.ts` (12 passed), `flutter test test/workout_flow_test.dart` | Berat badan, lingkar pinggang/dada/pinggul, update bobot user di DB, perhitungan delta kg, ringkasan riwayat |
| **F13** | Pelacak Gym & Sesi Latihan | TERVERIFIKASI | `vitest tests/workoutsAndProgress.test.ts`, `flutter test test/workout_flow_test.dart` | 81 katalog latihan gym, sesi latihan aktif, set/reps/weight logging, rest timer 90s, akumulasi total beban volume kg |
| **F14** | Program & Rutinitas Latihan | TERVERIFIKASI | `vitest tests/workoutsAndProgress.test.ts`, `flutter test test/workout_flow_test.dart` | Rutinitas kustom & template, mulai sesi langsung dari rutinitas, deteksi otomatis Rekor Pribadi (PR) dengan rumus Brzycki 1RM |
| **F15** | AI Workout Generator | TERVERIFIKASI | `vitest tests/workoutsAndProgress.test.ts`, `flutter test test/workout_flow_test.dart` | Generator rutinitas terstruktur otomatis berdasarkan goal, hari per minggu, dan alat, otomatis tersimpan ke DB rutinitas |
| **F16** | XP, Level & Achievements | BELUM | Belum diuji | Event idempoten, audit log, limit XP harian (cap 500 XP), reward kebiasaan sehat |
| **F17** | Tantangan & Peringkat (Leaderboard) | BELUM | Belum diuji | Daily/weekly challenge, streak, XP leaderboard dengan tie-break Asia/Jakarta |
| **F18** | Komunitas & Grup | BELUM | Belum diuji | Grup publik/privat, post, reaction, report & moderasi konten |
| **F19** | Insight Harian & Mingguan | BELUM | Belum diuji | Query deterministik aktual (bedakan tanpa data vs nol), ringkasan progres mingguan |
| **F20** | Air, Langkah & Aktivitas | SEBAGIAN | `vitest tests/nutrition.test.ts`, `flutter test test/nutrition_flow_test.dart` | Pencatatan air manual (+250ml, +500ml) TERVERIFIKASI; sensor langkah/aktivitas diuji di Fase 8 |
| **F21** | Notifikasi & Pengingat | BELUM | Belum diuji | Local notifications non-shaming, pengingat makan & hidrasi |
| **F22** | Pengaturan, Ekspor & Hapus Akun | SEBAGIAN | `vitest tests/authAndProfile.test.ts` (export & hard delete passed) | Ekspor JSON akun lengkap & hard delete akun backend cascade (UU PDP) terverifikasi; integrasi UI di Fase 8/9 |

---

## 2. Fase Eksekusi & Status

1. [x] **Fase 1: Audit Sistem & Lingkungan** (Selesai)
2. [x] **Fase 2: Fondasi & Desain** (F00 Selesai & Terverifikasi)
3. [x] **Fase 3: Autentikasi & Persistensi** (F01 Selesai & Terverifikasi, F22 sebagian)
4. [x] **Fase 4: Inti Nutrisi** (F05, F06, F07 Selesai & Terverifikasi, F03 PERLU-UJI-LIVE, F20 sebagian)
5. [x] **Fase 5: AI Makanan & Coach** (F02, F04, F08 Selesai & Terverifikasi)
6. [x] **Fase 6: Resep & Rencana** (F09, F10, F11 Selesai & Terverifikasi)
7. [x] **Fase 7: Gym & Progres** (F12, F13, F14, F15 Selesai & Terverifikasi)
8. [ ] **Fase 8: XP, Peringkat, Komunitas & Notifikasi** (F16, F17, F18, F20, F21)
9. [ ] **Fase 9: Insight, Integrasi Akhir & Verifikasi** (F19, Full Regression Suite, Clean ZIP)

---

## 3. Hasil Pengujian Terakhir (Fase 7)
- **Backend Vitest:** 54 passed (7 test files, 100% pass)
  - `tests/workoutsAndProgress.test.ts`: 12 tests passed
- **Flutter Widget Tests:** 20 passed (7 test files, 100% pass)
  - `test/workout_flow_test.dart`: 5 tests passed (WorkoutsScreen tabs, ActiveWorkoutSessionSheet, AiWorkoutGeneratorModal, BodyMeasurementModal)

---

## 4. Langkah Berikutnya (Fase 8: XP, Peringkat, Komunitas & Notifikasi)
- **F16: XP, Level & Achievements**
  - Database table: `xp_audit_logs`, `user_levels`, `achievements`, `user_achievements`.
  - Idempotency key per aksi: log meal (+10 XP), log workout (+25 XP), cap 500 XP per hari per user.
- **F17: Tantangan & Peringkat (Leaderboard)**
  - Leaderboard mingguan teragregasi dengan timezone kanonik Asia/Jakarta, tie-break adil (waktu capaian XP lebih awal).
- **F18: Komunitas & Grup**
  - CRUD grup publik/privat, forum postingan berbagi meal & workout log, reaksi semangat (kudos), moderasi & pelaporan konten.
- **F20 & F21: Notifikasi Lokal & Abstraksi Sensor Health**
  - Layanan notifikasi lokal ramah & edukatif (pengingat air, evaluasi hari ini), fallback sehat jika sensor tidak aktif.
