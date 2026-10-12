# Cal Application - Progress Tracker

**Mode Eksekusi:** OTONOM  
**Tanggal Terakhir Diperbarui:** 2026-10-12  
**Fase Saat Ini:** Fase 5 (Selesai) → Memulai Fase 6 (Resep & Rencana: F09, F10, F11)  
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
| **F12** | Progres Tubuh & Ukuran | BELUM | Belum diuji | Berat, lingkar pinggang, foto privat (opsional, visual check pose) |
| **F13** | Pelacak Gym & Sesi Latihan | BELUM | Belum diuji | 80 library latihan, set/rep/beban, rest timer, PR auto-detect |
| **F14** | Program & Rutinitas Latihan | BELUM | Belum diuji | Rutinitas multi-hari, start session dari routine, volume tracker |
| **F15** | AI Workout Generator | BELUM | Belum diuji | Generator program latihan berdasarkan tujuan/alat & text parser |
| **F16** | XP, Level & Achievements | BELUM | Belum diuji | Event idempoten, audit log, limit XP harian, reward kebiasaan |
| **F17** | Tantangan & Peringkat (Leaderboard) | BELUM | Belum diuji | Daily/weekly challenge, streak, XP leaderboard, anti-cheat |
| **F18** | Komunitas & Grup | BELUM | Belum diuji | Grup publik/privat, feed, reaction, report/block/moderasi |
| **F19** | Insight Harian & Mingguan | BELUM | Belum diuji | Query deterministik aktual (bedakan tanpa data vs nol), narasi AI |
| **F20** | Air, Langkah & Aktivitas | SEBAGIAN | `vitest tests/nutrition.test.ts`, `flutter test test/nutrition_flow_test.dart` | Pencatatan air manual (+250ml, +500ml) TERVERIFIKASI; sensor langkah/aktivitas diuji di Fase 8 |
| **F21** | Notifikasi & Pengingat | BELUM | Belum diuji | Local notifications non-shaming, push abstraction |
| **F22** | Pengaturan, Ekspor & Hapus Akun | SEBAGIAN | `vitest tests/authAndProfile.test.ts` (export & hard delete passed) | Ekspor JSON akun lengkap & hard delete akun backend cascade (UU PDP) terverifikasi; pengaturan privasi & notifikasi akan diselesaikan di Fase 8 |

---

## 2. Fase Eksekusi & Status

1. [x] **Fase 1: Audit Sistem & Lingkungan** (Selesai)
2. [x] **Fase 2: Fondasi & Desain** (F00 Selesai & Terverifikasi)
3. [x] **Fase 3: Autentikasi & Persistensi** (F01 Selesai & Terverifikasi, F22 sebagian)
4. [x] **Fase 4: Inti Nutrisi** (F05, F06, F07 Selesai & Terverifikasi, F03 PERLU-UJI-LIVE, F20 sebagian)
5. [x] **Fase 5: AI Makanan & Coach** (F02, F04, F08 Selesai & Terverifikasi)
6. [x] **Fase 6: Resep & Rencana** (F09, F10, F11 Selesai & Terverifikasi)
7. [ ] **Fase 7: Gym & Progres** (F13, F14, F15, F12)
8. [ ] **Fase 8: XP, Peringkat, Komunitas & Notifikasi** (F16, F17, F18, F21, F20 sensor)
9. [ ] **Fase 9: Insight, Integrasi Akhir & Verifikasi** (F19, Full Regression, Clean ZIP)

---

## 3. Langkah Berikutnya (Fase 7: Gym & Progres)
- Implementasi F13 (Pelacak Gym & Sesi Latihan):
  - Katalog 81 latihan gym terverifikasi dengan target otot, kategori, alat, dan instruksi.
  - Sesi latihan aktif (live workout session): pencatatan set, repetisi, beban kg, RPE, deteksi otomatis Rekor Pribadi (PR) dengan rumus Brzycki 1RM.
  - Rest timer antar set dan kalkulasi total volume beban (kg) deterministik.
- Implementasi F14 (Program & Rutinitas Latihan):
  - Pembuatan rutinitas latihan multi-hari (Push/Pull/Legs, Upper/Lower, Full Body).
  - Mulai sesi workout langsung dari template rutinitas.
- Implementasi F15 (AI Workout Generator):
  - Generator program latihan berdasarkan tujuan (hipertrofi, kekuatan, daya tahan), frekuensi hari/minggu, dan ketersediaan alat (gym komersial, dumbbell rumah, bodyweight).
- Implementasi F12 (Progres Tubuh & Ukuran):
  - Catatan berat badan harian, lingkar pinggang, dada, pinggul, dan foto progres privat (opsional).
  - Grafik tren berat badan dan perbandingan ukuran.
- Automated tests backend (vitest) dan Flutter widget tests.

