# Log Kualitas Data: Klinik Medinara

Dokumen ini mencatat setiap masalah yang ditemukan pada data mentah (`raw_*`), jumlah baris yang terdampak, keputusan penanganannya, dan di mana penanganan itu dilakukan. Semua angka dihitung dari data, dan bisa ditelusuri ke skrip di folder `sql/`.

**Status:** `Selesai` = ditangani di `sql/02_cleaning.sql` dan diverifikasi di `sql/02b_verify_clean_data.sql`. `Dicatat` = tidak diubah di data, tetapi diperhitungkan saat analisis.

## A. Masalah yang Dibersihkan

| # | Masalah | Tabel.Kolom | Baris terdampak | Keputusan | Status |
|---|---|---|---|---|---|
| 1 | Tanggal memakai 3 format campur | appointments.appt_date | 3.000 dari 5.000 bukan format `YYYY-MM-DD` (1.750 berformat `DD/MM/YYYY`, 1.250 berformat `DD-MM-YYYY`) | Dikonversi ke tipe `DATE`. Format garis miring dan strip keduanya **hari-bulan-tahun**. Bukti: 1.869 nilai berangka pertama > 12, dan 0 nilai berangka kedua > 12 (query V5) | Selesai |
| 2 | Tanggal memakai 3 format campur | prescriptions.prescribed_date | 3.601 dari 6.000 bukan format `YYYY-MM-DD` (2.116 dan 1.485) | Dikonversi ke `DATE` dengan aturan yang sama. Setelah konversi, tanggal resep identik dengan tanggal appointment terkait pada 6.000 dari 6.000 baris (query V6) | Selesai |
| 3 | Kode ICD kosong | diagnoses.icd_code | 698 dari 3.880 (18%) | Dibiarkan kosong, ditandai di kolom baru `icd_status = 'Tidak terkode'`. Tidak dibuang agar diagnosis tetap terhitung, tidak diisi agar tidak menyesatkan | Selesai |
| 4 | Golongan darah kosong | patients.blood_type | 300 dari 2.000 | Diisi `'Tidak diketahui'` | Selesai |
| 5 | Nomor telepon kosong | patients.phone | 160 dari 2.000 | Dibiarkan kosong (NULL). Tidak dipakai dalam analisis. Kolom disimpan sebagai teks sehingga angka 0 di depan tidak hilang | Selesai |
| 6 | Biaya selalu sama dengan tarif dokter, termasuk untuk appointment batal, no-show, dan pasien BPJS | appointments.fee_idr | 5.000 dari 5.000 | `fee_idr` dipahami sebagai tarif nominal, bukan pendapatan riil. Kolom baru `revenue_idr` hanya terisi untuk status `completed`: Rp 736.435.000 dari tarif nominal Rp 920.790.000 | Selesai |
| 7 | Kolom bertipe teks padahal angka, waktu, atau boolean | appt_time, fee_idr, duration_days, quantity, experience_years, consultation_fee_idr, follow_up_required | Semua baris | Dikonversi ke `TIME`, `INTEGER`, dan `BOOLEAN` | Selesai |
| 8 | Belum ada kolom turunan untuk analisis waktu | appointments | 5.000 | Ditambahkan `appt_month`, `appt_dow` (1 = Senin sampai 7 = Minggu), dan `appt_hour` | Selesai |
| 9 | Relasi antartabel belum dijamin | semua tabel bersih | - | Ditambahkan primary key dan foreign key. Pembuatan constraint berhasil, artinya tidak ada ID ganda maupun ID yatim | Selesai |

## B. Temuan yang Dicatat (Tidak Diubah di Data)

| # | Temuan | Baris terdampak | Cara ditangani dalam analisis | Status |
|---|---|---|---|---|
| 10 | Appointment `completed` tanpa catatan diagnosis | 120 dari 4.000 | Tetap dihitung sebagai kunjungan, dikeluarkan dari analisis diagnosis dan obat | Dicatat |
| 11 | Pasien terdaftar tanpa appointment | 169 dari 2.000 | Dikeluarkan dari analisis retensi dan RFM | Dicatat |
| 12 | Nama pasien tidak unik | 541 nama dipakai lebih dari satu pasien | Pasien selalu diidentifikasi dengan `patient_id`, tidak pernah dengan nama | Dicatat |
| 13 | NIK tersamar identik pada dua pasien berbeda | 2 pasien | Kemungkinan efek penyamaran (hanya sebagian digit yang tampak). Tidak dipakai sebagai pengenal | Dicatat |
| 14 | Kunjungan ke dokter Anak oleh pasien berusia 18 tahun ke atas | 437 dari 576 kunjungan Anak | Tidak mungkin terjadi pada klinik sungguhan, sehingga data tampak sintetis. Tidak ditarik kesimpulan klinis | Dicatat |
| 15 | Kunjungan pasien laki-laki ke dokter Kandungan | 197 dari 377 kunjungan Kandungan | Sama seperti di atas | Dicatat |
| 16 | Keluhan sering tidak selaras dengan diagnosis | Tidak dihitung | Analisis diagnosis dan obat hanya bersifat deskriptif | Dicatat |
| 17 | Data parsial di ujung periode | 2021: 177 appointment (mulai 4 Juni), 2025: 194 appointment (hanya Januari) | Perbandingan antartahun memakai rata-rata per bulan, bukan total | Dicatat |

## C. Verifikasi Pembersihan

Semua query berikut ada di `sql/02b_verify_clean_data.sql`.

| Query | Yang dicek | Hasil yang diharapkan |
|---|---|---|
| V1 | Jumlah baris tabel bersih sama dengan tabel mentah | Selisih 0 di kelima tabel |
| V2 | Tidak ada tanggal gagal dikonversi | 0 |
| V3 | Rentang tanggal | 2021-06-04 sampai 2025-01-31 |
| V4 | Contoh konversi per format | `03/05/2023` menjadi 3 Mei 2023 |
| V5 | Bukti format hari-bulan | Angka pertama > 12: 1.869, angka kedua > 12: 0 |
| V6 sampai V8 | Konsistensi tanggal resep, pasien, dan registrasi | 0 pelanggaran |
| V9 dan V10 | Revenue hanya dari `completed` | Rp 736.435.000, status sesuai |
| V11 | Penanganan nilai kosong | 698, 300, 160 |
| V13 dan V14 | Diagnosis dan pasien tanpa kunjungan | 120 dan 169 |
| V15 | Tipe data kolom | Bukan `text` semua |

## D. Catatan Metodologi

- Tabel `raw_*` tidak pernah diubah. Pembersihan menghasilkan tabel baru sehingga bisa diulang kapan saja.
- Konversi tanggal memakai pengenalan pola (regex) per format. Nilai yang tidak cocok dengan format mana pun akan menjadi `NULL` dan ditangkap oleh query V2, tidak dibiarkan lolos diam-diam.
- Data bersifat fiktif (tampak sintetis). Walaupun demikian, CSV mentah tidak dipublikasikan di repositori ini sebagai kebiasaan menjaga data pasien.
