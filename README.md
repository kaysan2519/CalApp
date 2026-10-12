# Cal — Modern Fitness, Nutrition, Gym, and Community Application

> **Cal** adalah asisten fitness personal komprehensif berbasis **Flutter** dan **Node.js / Express / TypeScript** dengan basis data **PostgreSQL 18**, dirancang khusus untuk pasar Indonesia dengan dukungan makanan lokal, satuan rumah tangga nusantara, pelacak latihan gym berakurasi tinggi, gamifikasi kebiasaan sehat, dan komunitas suportif.

---

## 🌟 Fitur Utama (F00 – F22)

### 🥗 Nutrisi & Pelacak Makanan
- **F00 Fondasi Arsitektur:** Riverpod, GoRouter, token JWT di penyimpanan aman, antrean offline idempotensi.
- **F01 Akun & Profil:** Formula Mifflin-St Jeor dengan batas kalori aman (*calorie floors*: min 1200 kkal wanita, min 1500 kkal pria) dan *age gate* ketat (≥ 18 tahun).
- **F02 AI Food Vision:** Analisis foto makanan dengan model vision terstruktur, pencocokan database lokal, dan badge transparan "Estimasi AI".
- **F03 Pemindai Barcode:** Lookup barcode kemasan makanan via Open Food Facts (ODbL) dengan caching lokal.
- **F04 Teks Bahasa Alami:** Parsing bahasa Indonesia sehari-hari ("nasi 2 centong, 2 butir telur rebus") dengan normalisasi takaran rumah tangga ke gram.
- **F05 Pencarian & Input Manual:** Database makanan lokal toleran salah ketik, makanan kustom pengguna, dan pengaturan porsi.
- **F06 Dashboard Nutrisi Harian:** Target kalori, makronutrisi (protein, karbohidrat, lemak), air minum, dan 4 slot waktu makan.
- **F07 Riwayat & Ringkasan:** Rekap harian dan mingguan dengan sinkronisasi otomatis.
- **F08 AI Nutrition Coach:** Konsultasi nutrisi *context-aware* dengan batasan medis aman.

### 🍲 Resep Sehat & Perencana Terpadu
- **F09 20 Resep Sehat Nusantara:** Resep lokal tinggi protein/rendah lemak, kalkulasi scaling porsi dinamis (0.5x, 1x, 2x), dan konversi sekali sentuh ke log makanan.
- **F10 Generator Menu Harian AI:** Rencana menu 1-hari seimbang berbasis resep DB dalam toleransi kalori aman (±10%).
- **F11 Rencana Harian Terpadu:** Dashboard terpadu menyatukan target nutrisi, hidrasi (+250ml), jadwal gym aktif, rekomendasi menu, dan checklist harian.

### 🏋️ Gym, Kekuatan & Progres Tubuh
- **F12 Progres Tubuh & Ukuran:** Catatan berat badan harian, lingkar pinggang, dada, pinggul, perhitungan delta kg, dan sinkronisasi bobot profil.
- **F13 Pelacak Gym & Sesi Aktif:** 81 katalog latihan gym, live workout tracker (set, repetisi, beban kg), rest timer 90 detik, dan akumulasi total volume beban kg.
- **F14 Rekor Pribadi (PR) & Rutinitas:** Perhitungan 1RM deterministik dengan **Rumus Brzycki**, auto-deteksi rekor beban tertinggi baru.
- **F15 AI Workout Generator:** Rancang program latihan terstruktur otomatis berdasarkan tujuan (*hypertrophy, strength, endurance*), frekuensi mingguan, dan ketersediaan alat.

### 🏆 Gamifikasi, Komunitas & Notifikasi
- **F16 XP, Level & Achievements:** Audit log transaksi XP idempoten, batas cap harian 500 XP (anti-cheat), rumus level kuadratik progresif, dan lencana prestasi kebiasaan.
- **F17 Peringkat & Misi (Leaderboard):** Papan peringkat mingguan dengan zona waktu kanonik **Asia/Jakarta** dan tie-break capaian waktu tercepat.
- **F18 Komunitas & Grup Suportif:** Grup publik/privat, forum posting feed (+15 XP), reaksi apresiasi (*kudos* ❤️), komentar, serta moderasi & pelaporan konten ⚠️.
- **F19 Insight Mingguan:** Analisis 7-hari deterministik (rata-rata kalori, kepatuhan protein %, volume gym, narasi kebiasaan terstruktur).
- **F20 & F21 Pengingat Ramah & Sensor Health:** Notifikasi santun tanpa mempermalukan (*non-shaming*), jadwal hidrasi dan makan, serta abstraksi sensor langkah Health Connect.
- **F22 Hak Data Pribadi (UU PDP):** Ekspor seluruh arsip akun dalam format JSON dan hard delete akun permanen *cascade*.

---

## 🏗️ Struktur Arsitektur

```
CalApp/
├── backend/                  # REST API (Node.js, Express, TypeScript, PostgreSQL)
│   ├── src/
│   │   ├── config/           # Database pool, env, JWT config
│   │   ├── db/               # SQL Migrations (schema.sql), Seeders (seedData.ts)
│   │   ├── middleware/       # Auth guard, error handlers, rate limiting
│   │   └── modules/          # Auth, Profile, Nutrition, AI, Recipes, Workouts,
│   │                         # Gamification, Community, Notifications, Insights
│   └── tests/                # 67 Unit & Integration Tests (Vitest)
├── mobile/                   # Flutter Mobile Client (iOS & Android)
│   ├── lib/
│   │   ├── core/             # Design System, ApiClient Dio, TokenStorage, GoRouter
│   │   └── features/         # Auth, Nutrition, Workouts, Community, Today, Profile
│   └── test/                 # 27 Widget & Flow Tests (flutter test)
├── design-system/            # Semantic tokens & Theme configurations
└── docs/                     # PROGRESS.md, DECISIONS.md, NUTRITION_RULES.md, MANUAL_TEST.md
```

---

## 🚀 Panduan Menjalankan

### 1. Prasyarat
- **Node.js** v20+ atau v22+
- **PostgreSQL** v16+ atau v18+ (Port default: 5432)
- **Flutter SDK** v3.24+
- **Docker & Docker Compose** (Opsional untuk Postgres container)

### 2. Menjalankan Backend API
```bash
cd backend
npm install

# Konfigurasi environment
cp .env.example .env

# Jalankan migrasi dan seed katalog (makanan, resep, latihan gym, achievements)
npm run migrate
npm run seed

# Jalankan development server
npm run dev
# Server aktif di http://localhost:4000
```

### 3. Menjalankan Mobile App (Flutter)
```bash
cd mobile
flutter pub get

# Jalankan di emulator atau perangkat fisik
flutter run
```

---

## 🧪 Pengujian Otomatis (Testing Suite)

### Backend (Vitest — 67 Tests Passed)
```bash
cd backend
npm test
```
*Hasil:* 9 Test Suites, 67 Tests Passed (100% pass rate).

### Mobile (Flutter Test — 27 Tests Passed)
```bash
cd mobile
flutter test
```
*Hasil:* 9 Test Files, 27 Tests Passed (100% pass rate).

---

## 🔒 Kebijakan Keamanan & Etika Kesehatan
1. **Perhitungan Deterministik di Kode:** Angka kalori, makro, dan 1RM dihitung oleh rumus matematis terverifikasi di kode, bukan oleh LLM.
2. **Calorie Floors:** Sistem menolak target kalori ekstrem (<1200 kkal untuk wanita, <1500 kkal untuk pria).
3. **Age Gate:** Pengguna di bawah usia 18 tahun ditolak saat registrasi demi perlindungan kesehatan remaja.
4. **UU PDP (Kepatuhan Privasi):** Pengguna berhak mengekspor data arsip dan menghapus akun permanen secara mandiri.
5. **Non-Shaming Framing:** Seluruh pengingat dan pesan notifikasi menggunakan pendekatan suportif yang membangun kebiasaan positif.
