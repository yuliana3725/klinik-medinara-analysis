# Kamus Data: Klinik Medinara

Dokumen ini menjelaskan arti setiap tabel dan kolom pada dataset. Angka-angka di bawah dihitung dari data mentah (tabel `raw_*`) sebelum pembersihan.

**Periode data:** 4 Juni 2021 sampai 31 Januari 2025 (data 2021 dan 2025 hanya sebagian tahun).

**Relasi antartabel:**

```
patients (1) ──< appointments >── (1) doctors
                     │
                     │ 1 appointment punya 0 atau 1 diagnosis
                     ▼
                 diagnoses (1) ──< prescriptions
```

| Tabel | Baris | Satu baris mewakili |
|---|---|---|
| doctors | 25 | Satu dokter |
| patients | 2.000 | Satu pasien terdaftar |
| appointments | 5.000 | Satu janji temu pasien dengan dokter |
| diagnoses | 3.880 | Satu diagnosis dari satu janji temu |
| prescriptions | 6.000 | Satu item obat yang diresepkan |

---

## doctors

| Kolom | Arti | Catatan |
|---|---|---|
| doctor_id | ID dokter | Primary key, contoh `DOC01` |
| name | Nama lengkap dan gelar | Mengandung koma (contoh: `dr. Sari Hidayat, Sp.PD`), jadi dibungkus tanda kutip di CSV |
| specialization | Poli / spesialisasi | 8 nilai: Umum (8 dokter), Penyakit Dalam, Anak, Gigi (masing-masing 3), Kulit, Kandungan, Mata, THT (masing-masing 2) |
| schedule_days | Hari praktik | Teks bebas, contoh `Senin-Sabtu` atau `Senin,Rabu,Jumat` |
| phone | Nomor telepon dokter | Disimpan sebagai teks agar angka 0 di depan tidak hilang |
| experience_years | Lama pengalaman (tahun) | Angka |
| consultation_fee_idr | Tarif konsultasi (Rupiah) | Angka |

## patients

| Kolom | Arti | Catatan |
|---|---|---|
| patient_id | ID pasien | Primary key, contoh `PAT00001` |
| name | Nama pasien | **Tidak unik**: ada 541 nama yang dipakai lebih dari satu pasien. Jangan memakai nama sebagai pengenal |
| nik_masked | NIK yang sudah disamarkan | Enam digit awal saja. Satu pasangan pasien memiliki nilai yang sama (kemungkinan efek penyamaran) |
| dob | Tanggal lahir | Format `YYYY-MM-DD` |
| gender | Jenis kelamin | `Female` (1.040) dan `Male` (960) |
| address | Alamat | Teks |
| city | Kota | 13 kota, terbanyak Jakarta (500), Depok (300), Bekasi dan Tangerang (masing-masing 250) |
| phone | Nomor telepon | Kosong pada 160 pasien |
| blood_type | Golongan darah | A, B, AB, O. Kosong pada 300 pasien |
| registration_date | Tanggal registrasi | Format `YYYY-MM-DD` |
| insurance_type | Jenis jaminan | BPJS (1.200), Mandiri (400), Perusahaan (240), Umum (160) |

## appointments

| Kolom | Arti | Catatan |
|---|---|---|
| appt_id | ID janji temu | Primary key, contoh `APT00001` |
| patient_id | ID pasien | Foreign key ke `patients` |
| doctor_id | ID dokter | Foreign key ke `doctors` |
| appt_date | Tanggal janji temu | **Tiga format campur**: `YYYY-MM-DD` (2.000 baris), `DD/MM/YYYY` (1.750), `DD-MM-YYYY` (1.250). Format dengan garis miring dan strip keduanya hari-bulan-tahun |
| appt_time | Jam janji temu | Format `HH:MM` |
| complaint | Keluhan utama | 40 nilai berbeda |
| status | Status janji temu | `completed` (4.000), `cancelled` (400), `no_show` (350), `rescheduled` (250) |
| fee_idr | Biaya (Rupiah) | Berkisar 60.000 sampai 350.000. **Selalu sama dengan tarif dokter**, termasuk untuk janji temu batal dan no-show serta pasien BPJS. Jadi ini tarif nominal, bukan pendapatan riil |
| payment_method | Cara bayar | BPJS (2.410), Tunai (1.013), Transfer (1.002), Asuransi (575) |

## diagnoses

| Kolom | Arti | Catatan |
|---|---|---|
| diagnosis_id | ID diagnosis | Primary key, contoh `DGN0001` |
| appt_id | ID janji temu | Foreign key ke `appointments`. Semua diagnosis berasal dari janji temu berstatus `completed`, dan tiap janji temu punya paling banyak satu diagnosis |
| icd_code | Kode ICD | **Kosong pada 698 baris (18%)**. Terdapat 33 kode berbeda |
| description | Deskripsi diagnosis | Pada baris tanpa kode ICD, deskripsinya bersifat umum (contoh: "Diagnosis sementara", "Gejala umum tidak spesifik") |
| severity | Tingkat keparahan | `mild` (2.339), `moderate` (1.163), `severe` (378) |
| follow_up_required | Perlu tindak lanjut | `true` atau `false` |
| notes | Catatan klinis singkat | Kosong pada 1.552 baris |

## prescriptions

| Kolom | Arti | Catatan |
|---|---|---|
| rx_id | ID resep | Primary key, contoh `RX00001` |
| diagnosis_id | ID diagnosis | Foreign key ke `diagnoses`. Satu diagnosis memiliki 1 sampai 4 resep, jadi hati-hati dengan double counting saat JOIN |
| patient_id | ID pasien | Konsisten dengan pasien pada janji temu terkait |
| medicine_name | Nama obat | Contoh: Omeprazole 20mg, Amoxicillin 500mg |
| dosage | Aturan pakai | Teks bebas, contoh `2x1 tablet` |
| route | Rute pemberian | `oral` (4.411), `topikal` (1.001), `inhaler` (377), `injeksi` (211) |
| duration_days | Lama pengobatan (hari) | 3 sampai 30 |
| prescribed_date | Tanggal resep | **Tiga format campur**, sama seperti `appt_date`. Nilainya sama dengan tanggal janji temu terkait |
| quantity | Jumlah obat | 1 sampai 90 |

---

## Catatan dan Batasan Data

1. **Data tampak sintetis.** Distribusi hampir seragam dan beberapa pola tidak masuk akal secara klinis, antara lain kunjungan pasien dewasa ke dokter Anak, kunjungan pasien laki-laki ke dokter Kandungan, serta keluhan yang tidak selaras dengan diagnosis. Analisis difokuskan pada sisi operasional dan bisnis, bukan kesimpulan medis.
2. **Biaya bukan pendapatan riil.** Pendapatan dihitung hanya dari janji temu berstatus `completed`, dengan asumsi tarif nominal.
3. **Tidak semua janji temu selesai punya diagnosis.** Dari 4.000 janji temu `completed`, ada 3.880 yang punya diagnosis. Sisanya (120) tidak punya catatan diagnosis.
4. **Ada pasien tanpa kunjungan.** 169 pasien terdaftar tidak memiliki janji temu sama sekali.
5. **Data parsial di ujung periode.** Tahun 2021 (177 janji temu) dan 2025 (194 janji temu) hanya mencakup sebagian tahun, sementara 2024 mencakup 2.551 janji temu.
6. **Data pribadi.** Dataset memuat nama, alamat, dan diagnosis. CSV mentah tidak dipublikasikan di repositori ini.
