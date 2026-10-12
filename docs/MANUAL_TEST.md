# Cal - Panduan Pengujian Manual & Live (docs/MANUAL_TEST.md)

Dokumen ini memuat daftar fitur berstatus **PERLU-UJI-LIVE** beserta instruksi langkah demi langkah yang harus dijalankan pada perangkat fisik (smartphone Android/iOS) dan kredensial/layanan yang perlu disediakan.

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
- API Key provider AI yang aktif di backend `.env` (salah satu dari: `GEMINI_API_KEY`, `OPENAI_API_KEY`, atau `ANTHROPIC_API_KEY`).
- Kamera perangkat atau foto makanan di galeri foto perangkat.

### Langkah Uji di Perangkat:
1. Isi salah satu kunci API di `backend/.env`.
2. Buka tab **Nutrisi** -> ketuk **Foto Makanan (AI)**.
3. Ambil foto piring makanan nyata (misal: sepiring nasi dengan ayam dan tempe).
4. Pastikan aplikasi menampilkan draf kandidat makanan dengan label "Estimasi AI", perkiraan porsi, dan tingkat keyakinan (confidence score).
5. Edit salah satu porsi dan simpan ke catatan makanan harian.
6. Coba ambil foto benda bukan makanan (misal: meja atau buku): pastikan AI mendeteksi non-makanan dengan aman dan menawarkan opsi input manual.

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
