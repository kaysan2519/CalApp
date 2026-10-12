# Cal Application - Progress Tracker

**Mode Eksekusi:** OTONOM  
**Tanggal Terakhir Diperbarui:** 2026-10-12  
**Fase Saat Ini:** Fase 3 (Selesai) → Memulai Fase 4 (Inti Nutrisi)  
**Branch Git:** `feat/cal-build`

---

## 1. Matriks Fitur (F00 – F22)

| ID | Fitur | Status | Bukti / Pengujian | Catatan & Keterbatasan |
|:---|:---|:---:|:---|:---|
| **F00** | Fondasi & Arsitektur | TERVERIFIKASI | `flutter test` (4 tests passed), `vitest` (2 tests passed), `flutter analyze` clean | Tema Flutter Emerald/Orange/Indigo, CalMacroColors ThemeExtension, GoRouter 4 tabs, TokenStorage, ApiClient Dio, OfflineQueue UUIDv4 |
| **F01** | Akun, Profil & Target Nutrisi | TERVERIFIKASI | `vitest tests/nutritionCalculator.test.ts` (5 passed), `vitest tests/authAndProfile.test.ts` (11 passed), `flutter test test/auth_flow_test.dart` (3 passed) | Register, login, refresh rotation, age gate >= 18 strict, rumus Mifflin-St Jeor, batas lantai 1200/1500 kkal, override target manual, persistensi PostgreSQL |
| **F02** | Foto Makanan (AI Vision) | BELUM | Belum diuji | Vision model + JSON schema, crop/kompres, review & edit sebelum simpan |
| **F03** | Barcode Scanner (Open Food Facts) | BELUM | Belum diuji | Scanner kamera, query OFF API cache, fallback manual entry |
| **F04** | Teks Bahasa Sehari-hari | BELUM | Belum diuji | LLM entity extraction (satuan lokal: centong, potong, sdm), normalisasi gram |
| **F05** | Pencarian & Input Manual Makanan | BELUM | Belum diuji | DB pangan lokal/nasional, porsi, favorit, custom food |
| **F06** | Dashboard & Tracker Harian | BELUM | Belum diuji | Kalori ring, makro bars, meal slots, log air, snapshot gizi |
| **F07** | Riwayat & Ringkasan Makanan | BELUM | Belum diuji | Riwayat per hari, edit/hapus recalculate, ringkasan mingguan |
| **F08** | AI Nutrition Coach | BELUM | Belum diuji | Chat context-aware, server-side tool calling, safe bounds |
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
| **F20** | Air, Langkah & Aktivitas | BELUM | Belum diuji | Manual water tracking; Health Connect / Apple Health abstraction |
| **F21** | Notifikasi & Pengingat | BELUM | Belum diuji | Local notifications non-shaming, push abstraction |
| **F22** | Pengaturan, Ekspor & Hapus Akun | SEBAGIAN | `vitest tests/authAndProfile.test.ts` (export & hard delete passed) | Ekspor JSON akun lengkap & hard delete akun backend cascade (UU PDP) terverifikasi; pengaturan privasi & notifikasi akan diselesaikan di Fase 8 |

---

## 2. Fase Eksekusi & Status

1. [x] **Fase 1: Audit Sistem & Lingkungan** (Selesai)
2. [x] **Fase 2: Fondasi & Desain** (F00 Selesai & Terverifikasi)
3. [x] **Fase 3: Autentikasi & Persistensi** (F01 Selesai & Terverifikasi, F22 sebagian)
4. [ ] **Fase 4: Inti Nutrisi** (F05, F06, F07, F03, F20 air, Food DB & Unit Conversion)
5. [ ] **Fase 5: AI Makanan & Coach** (F02, F04, F08)
6. [ ] **Fase 6: Resep & Rencana** (F09, F10, F11)
7. [ ] **Fase 7: Gym & Progres** (F13, F14, F15, F12)
8. [ ] **Fase 8: XP, Peringkat, Komunitas & Notifikasi** (F16, F17, F18, F21, F20 sensor)
9. [ ] **Fase 9: Insight, Integrasi Akhir & Verifikasi** (F19, Full Regression, Clean ZIP)

---

## 3. Langkah Berikutnya
- Melanjutkan ke Fase 4: Inti Nutrisi (F05, F06, F07, F03, F20 air).
- Implementasi API database makanan: pencarian toleran salah ketik (synonym, ILIKE), custom food creation, barcode query Open Food Facts cache.
- Implementasi endpoint pencatatan makanan: `/nutrition/log` (breakfast, lunch, dinner, snack), snapshot nilai gizi, auto-recalculate total, update dan delete item.
- Implementasi pencatatan air harian (`/nutrition/water`).
- Integrasi ke UI mobile: NutritionScreen dengan 4 slot waktu makan, search modal, barcode scan fallback, water logger.
- Uji integrasi backend dan widget test.
