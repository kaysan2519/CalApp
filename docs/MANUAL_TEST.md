# Cal - Panduan Pengujian Manual & Live (docs/MANUAL_TEST.md)

Dokumen ini memuat daftar fitur berstatus **PERLU-UJI-LIVE** beserta instruksi langkah demi langkah yang harus dijalankan pada perangkat fisik (smartphone Android/iOS) dan kredensial/layanan yang perlu disediakan.

## 0. Pemeriksaan Lokal Flutter dan Artefak Android

Pemeriksaan lokal terakhir pada 2026-10-12:

1. Jalankan `cd mobile`.
2. Jalankan `flutter analyze --no-pub`; hasil audit: **No issues found**.
3. Jalankan `flutter test --no-pub --concurrency=1`; hasil audit: **27/27 tes lulus**.
4. Jalankan `flutter build apk --debug --no-pub --verbose`; hasil audit: build berhasil.
5. APK debug tersedia di `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
6. Instal APK pada emulator/perangkat dan lanjutkan uji live di bawah. Build dan widget tests tidak menggantikan verifikasi alur API end-to-end di perangkat.

---

## 1. F03: Pemindai Barcode Kamera Fisik (Open Food Facts)

### Kebutuhan:
- Perangkat fisik Android atau iOS yang memiliki kamera belakang berfungsi.
- Izin akses kamera (`CAMERA`).
- Contoh kemasan produk makanan ber-barcode (misal: bungkus Indomie, susu kemasan, biskuit).

### Langkah Uji di Perangkat:
1. Buka aplikasi Cal di smartphone.
2. Navigasi ke tab **Nutrisi** -> pilih salah satu slot (misal: Makan Siang) -> ketuk tombol **Pindai Barcode**.
3. Saat pop-up izin kamera muncul, pilih **Izinkan (Allow)**.
4. Arahkan kamera ke barcode kemasan produk makanan.
5. Verifikasi bahwa sistem mendeteksi barcode, memanggil API backend, dan menampilkan rincian produk (Nama, Merek, Kalori, Protein, Karbohidrat, Lemak).
6. Uji barcode produk yang tidak terdaftar: pastikan aplikasi menampilkan peringatan ramah bahwa produk belum terdaftar dan menawarkan opsi **Input Manual / Simpan Makanan Kustom**.

---

## 2. F02: Foto Makanan AI Vision (Phase 5)

### Kebutuhan:
- `OPENAI_API_KEY` yang aktif di `backend/.env` dan `AI_PROVIDER=openai` (`OPENAI_MODEL` opsional, default `gpt-4o-mini`). Provider produksi yang diimplementasikan saat ini adalah OpenAI.
- Kamera perangkat atau foto makanan di galeri foto perangkat.

### Langkah Uji di Perangkat:
1. Isi `OPENAI_API_KEY` di `backend/.env`, nyalakan backend, dan jangan menaruh key di Flutter.
2. Buka tab **Nutrisi** -> ketuk **Foto Makanan (AI)**.
3. Ambil foto piring makanan nyata (misal: sepiring nasi dengan ayam dan tempe).
4. Pastikan aplikasi menampilkan draf kandidat makanan dengan label "Estimasi AI", perkiraan porsi, dan tingkat keyakinan (confidence score).
5. Edit salah satu porsi dan simpan ke catatan makanan harian.
6. Coba ambil foto benda bukan makanan (misal: meja atau buku): pastikan AI mendeteksi non-makanan dengan aman dan menawarkan opsi input manual.

## 5. Autentikasi, onboarding, sesi dan edit profil

### Kebutuhan:
- Backend dan PostgreSQL berjalan dengan skema terbaru (`npm run migrate`).
- Emulator Android; perangkat fisik menggunakan alamat LAN backend lewat `--dart-define=API_BASE_URL=http://<alamat-lan>:4000/api/v1`.

### Langkah Uji:
1. Buat akun dengan umur 18–120 tahun, tinggi dan berat yang diisi sendiri. Pastikan validasi menolak nilai di luar batas dan tidak ada angka contoh yang dipakai.
2. Selesaikan langkah tujuan, aktivitas, latihan, peralatan, preferensi makanan, alergi, pantangan dan batasan (kolom opsional boleh kosong).
3. Pastikan layar rekomendasi memberi status yang jelas bila OpenAI belum dikonfigurasi; target nutrisi berasal dari kalkulasi backend.
4. Tutup dan buka ulang aplikasi. Pastikan akun yang telah menyelesaikan onboarding menuju dashboard.
5. Buka Profil, edit data dasar dan preferensi, simpan, lalu muat ulang profil. Pastikan data dan target hasil hitung tersimpan.
6. Login lagi dengan akun yang sama dan uji logout. Uji refresh token dengan sesi yang telah kedaluwarsa; sesi valid harus diperbarui, sesi tak valid harus meminta login kembali.

## 6. XP, rank dan leaderboard

1. Catat meal atau selesaikan latihan yang memiliki set tercatat. Pastikan XP tetap berasal dari event server dan aktivitas yang sama tidak dibayar dua kali.
2. Buka Rank dari dashboard. Pastikan total XP, level, rank, progres, riwayat dan daftar peringkat cocok dengan data backend.
3. Uji leaderboard mingguan dan global, termasuk akun tanpa XP; posisi kosong harus dijelaskan tanpa pengguna contoh.
4. Kirim permintaan XP dengan `xpAmount` buatan dan aktivitas milik akun lain. Server harus mengabaikan nilai XP klien dan menolak aktivitas asing/tidak tercatat.

---

## 3. F20: Sensor Langkah & Health Connect / Apple Health (Phase 8)

### Kebutuhan:
- Perangkat Android dengan Health Connect terinstal atau perangkat iPhone dengan Apple Health.
- Izin pembacaan langkah dan aktivitas fisik (`ACTIVITY_RECOGNITION` / Health permissions).

### Langkah Uji di Perangkat:
1. Buka pengaturan aplikasi Cal di smartphone.
2. Aktifkan integrasi Health Connect / Apple Health.
3. Berikan izin baca langkah dan kalori aktif.
4. Buka tab **Hari Ini**: verifikasi bahwa jumlah langkah harian tersinkronisasi otomatis.

---

## 4. F21: Notifikasi Pengingat Lokal & Push (Phase 8)

### Kebutuhan:
- Izin notifikasi sistem (`POST_NOTIFICATIONS` Android 13+).

### Langkah Uji di Perangkat:
1. Aktifkan pengingat minum air dan pencatatan makanan di Pengaturan.
2. Verifikasi notifikasi lokal muncul sesuai jadwal tanpa pesan yang menghakimi/shaming.
