# Klinik Medinara Analysis

Analisis data operasional sebuah klinik (kunjungan, pendapatan, dokter, no-show, dan pasien) menggunakan PostgreSQL, Python, dan dashboard. Proyek ini mengikuti alur kerja seorang data analyst: dari data mentah yang berantakan, pembersihan, analisis, sampai rekomendasi.

> **Status proyek:** database, pembersihan data, dan analisis tren selesai. Analisis dokter dan no-show sedang berjalan.

## Pertanyaan Bisnis

1. Bagaimana tren kunjungan dan pendapatan per bulan, dan kapan puncaknya?
2. Poli dan dokter mana yang paling produktif?
3. Seberapa tinggi no-show dan pembatalan, dan bagaimana polanya?
4. Berapa persen pasien yang kembali berkunjung (retensi)?
5. Seperti apa segmentasi pasien berdasarkan RFM (recency, frequency, monetary)?
6. Diagnosis dan obat apa yang paling sering muncul?

| # | Pertanyaan | Status |
|---|---|---|
| 1 | Tren kunjungan dan revenue | Selesai |
| 2 | Kinerja dokter dan poli | Berikutnya |
| 3 | No-show dan pembatalan | Berikutnya |
| 4 | Retensi dan cohort pasien | Belum |
| 5 | Segmentasi RFM | Belum |
| 6 | Diagnosis dan obat | Belum |

## Dataset

Data klinik fiktif (tampak sintetis) periode **4 Juni 2021 sampai 31 Januari 2025**.

| Tabel | Baris | Isi |
|---|---|---|
| doctors | 25 | Dokter, spesialisasi, jadwal, tarif konsultasi |
| patients | 2.000 | Demografi, kota, jenis jaminan |
| appointments | 5.000 | Janji temu, status, biaya, metode bayar |
| diagnoses | 3.880 | Diagnosis dan tingkat keparahan |
| prescriptions | 6.000 | Obat yang diresepkan |

Relasi: `patients` → `appointments` ← `doctors`, lalu `appointments` → `diagnoses` → `prescriptions`.

Data mentah **tidak disertakan** di repositori karena berisi nama, alamat, dan diagnosis pasien. Penjelasan lengkap tiap kolom ada di [docs/data_dictionary.md](docs/data_dictionary.md).

## Temuan Sementara

Dari analisis tren kunjungan dan revenue:

- Rata-rata kunjungan per bulan naik dari **44,0** (2022) menjadi **170,9** (2024), tetapi laju pertumbuhannya melambat dan kurvanya cenderung mendatar sejak pertengahan 2024.
- Pertumbuhan revenue hampir seluruhnya berasal dari bertambahnya jumlah kunjungan, bukan kenaikan tarif (rata-rata sekitar Rp 184 ribu per kunjungan).
- Tidak ada hari atau jam yang menonjol secara statistik (uji chi-square, p > 0,05).
- Sekitar 20% appointment tidak selesai (batal, no-show, dijadwal ulang), setara Rp 184.355.000 tarif nominal. Ini menjadi bahan analisis berikutnya.

Detail, grafik, dan batasannya: [reports/findings_draft.md](reports/findings_draft.md)

## Struktur Repo

```
klinik-medinara-analysis/
├── data/
│   ├── raw/          # CSV asli (tidak di-commit)
│   └── processed/    # CSV agregat hasil analisis
├── sql/              # skrip SQL berurutan
├── notebooks/        # notebook analisis (Python)
├── reports/          # draf temuan dan grafik
├── docs/             # kamus data dan log kualitas data
├── dashboard/        # tangkapan layar dan tautan dashboard (menyusul)
└── README.md
```

## Skrip SQL

Jalankan berurutan:

| File | Fungsi |
|---|---|
| `sql/01_schema_and_load.sql` | Membuat tabel mentah `raw_*` |
| `sql/01b_verify_raw_data.sql` | Memverifikasi hasil impor CSV |
| `sql/02_cleaning.sql` | Membuat tabel bersih dengan tipe data yang benar |
| `sql/02b_verify_clean_data.sql` | Memverifikasi hasil pembersihan |
| `sql/03_visit_revenue_trend.sql` | Analisis tren kunjungan dan revenue |

## Cara Menjalankan Ulang

**Kebutuhan:** PostgreSQL 14 dan pgAdmin 4. Untuk notebook: Python 3 atau Google Colab.

1. Buat database kosong bernama `klinik_medinara`.
2. Siapkan lima file CSV (`doctors`, `patients`, `appointments`, `diagnoses`, `prescriptions`) di komputermu, misalnya di folder `data/raw/`.
3. Jalankan `sql/01_schema_and_load.sql` untuk membuat tabel mentah.
4. Impor tiap CSV ke tabel `raw_*` yang sesuai. Di pgAdmin: klik kanan tabel → Import/Export Data, lalu atur Header = ON, Delimiter `,`, Quote `"`, Escape `"`, Encoding UTF8.
5. Jalankan `sql/01b_verify_raw_data.sql`. Jumlah baris harus 25, 2.000, 5.000, 3.880, dan 6.000.
6. Jalankan `sql/02_cleaning.sql`, lalu `sql/02b_verify_clean_data.sql`.
7. Jalankan `sql/03_visit_revenue_trend.sql` satu query per langkah.
8. Notebook di `notebooks/` membaca file CSV agregat di `data/processed/` dan bisa dijalankan di Google Colab dengan mengunggah `monthly_trend.csv` dan `hari_jam.csv`.

## Catatan Data

- Tanggal pada `appointments` dan `prescriptions` memakai **tiga format campur**. Format dengan garis miring dan strip keduanya hari-bulan-tahun. Buktinya ada di [docs/data_quality_log.md](docs/data_quality_log.md).
- Biaya (`fee_idr`) selalu sama dengan tarif dokter, jadi **pendapatan hanya dihitung dari appointment berstatus `completed`** dan dibaca sebagai tarif nominal.
- Data 2021 (mulai 4 Juni) dan 2025 (hanya Januari) adalah **tahun parsial**, sehingga perbandingan antartahun memakai rata-rata per bulan.
- Data tampak sintetis dan memuat ketidakkonsistenan klinis, sehingga analisis difokuskan pada sisi operasional, bukan kesimpulan medis.

## Dokumentasi

- [Kamus data](docs/data_dictionary.md)
- [Log kualitas data](docs/data_quality_log.md)
- [Draf temuan: tren kunjungan dan revenue](reports/findings_draft.md)

## Tools

PostgreSQL 14, pgAdmin 4, SQL (CTE, window function), Python (pandas, matplotlib, seaborn, scipy), Google Colab, Git dan GitHub.
