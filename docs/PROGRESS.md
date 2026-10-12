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
| **F09** | Resep Sehat Indonesia | BELUM | Belum diuji | 20 seed resep lokal, scaling porsi, bahan ke log makanan |
| **F10** | Menu Harian AI | BELUM | Belum diuji | Generator menu berbasis inventaris/resep DB, toleransi kalori |
| **F11** | Rencana Harian Terpadu | BELUM | Belum diuji | Target nutrisi, jadwal gym, hidrasi, tantangan harian |
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
6. [ ] **Fase 6: Resep & Rencana** (F09, F10, F11)
7. [ ] **Fase 7: Gym & Progres** (F13, F14, F15, F12)
8. [ ] **Fase 8: XP, Peringkat, Komunitas & Notifikasi** (F16, F17, F18, F21, F20 sensor)
9. [ ] **Fase 9: Insight, Integrasi Akhir & Verifikasi** (F19, Full Regression, Clean ZIP)

---

## 3. Langkah Berikutnya (Fase 6: Resep & Rencana)
- Implementasi F09 (Resep Sehat Indonesia):
  - Catalog 20 resep lokal Indonesia di database dengan bahan, langkah, makro per porsi, waktu masak, tags (tinggi protein, rendah kalori, vegetarian).
  - Endpoint scaling porsi (`/api/v1/recipes/:id?servings=N`), hitung otomatis makro proporsional.
  - Endpoint konversi resep ke meal log (`POST /api/v1/recipes/:id/log-to-meal`).
- Implementasi F10 (Menu Harian AI):
  - Rekomendasi / generator menu harian cerdas berdasarkan target kalori & makro sisa pengguna hari ini.
  - Toleransi kalori ±10%, kombinasi sarapan, makan siang, makan malam dari database resep.
- Implementasi F11 (Rencana Harian Terpadu):
  - Dashboard tab rencana harian menyatukan target nutrisi, jadwal gym yang direncanakan, target hidrasi, dan tantangan harian.
- Flutter UI untuk modul Resep & Rencana Harian.
- Automated tests di backend (vitest) dan Flutter widget tests.

