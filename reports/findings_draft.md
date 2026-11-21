# Draf Temuan: Tren Kunjungan dan Revenue

**Periode data:** Juni 2021 sampai Januari 2025 (44 bulan)

**Definisi**
- **Kunjungan** = appointment berstatus `completed`
- **Revenue** = tarif nominal appointment `completed`, bukan pendapatan riil
- Perbandingan antartahun memakai **rata-rata per bulan**, karena 2021 (7 bulan) dan 2025 (1 bulan) adalah tahun parsial

**Gambaran umum:** dari 5.000 appointment, 4.000 (80%) berstatus selesai dan menghasilkan revenue nominal Rp 736.435.000. Sisanya batal (8%), no-show (7%), dan dijadwal ulang (5%).

---

## 1. Tren kunjungan: tumbuh pesat selama tiga tahun penuh

Rata-rata kunjungan per bulan naik dari **44,0** (2022) menjadi **93,5** (2023) dan **170,9** (2024), atau tumbuh 112,5% lalu 82,8%. Rata-rata revenue per bulan ikut naik dari Rp 8,28 juta menjadi Rp 17,17 juta dan Rp 31,41 juta.

Rata-rata revenue per kunjungan hampir tidak berubah, yaitu sekitar Rp 184 ribu (Rp 183.601 sampai Rp 188.239 pada 2022 sampai 2024). Artinya pertumbuhan revenue **hampir seluruhnya berasal dari bertambahnya jumlah kunjungan**, bukan dari kenaikan tarif.

**Implikasi:** klinik berkembang karena volume pasien, sehingga kapasitas dokter dan jadwal layak dipantau agar tidak menjadi kendala.

**Batasan:** 2021 hanya 7 bulan dan 2025 hanya 1 bulan, jadi keduanya tidak dipakai dalam perbandingan tahunan.

## 2. Laju pertumbuhan: masih positif, tetapi melambat

Laju pertumbuhan kunjungan rata-rata per bulan turun dari **7,2%** (2022) menjadi **5,2%** (2023) dan **2,8%** (2024). Pertumbuhan year-over-year pada pertengahan 2024 masih sekitar 107% sampai 115% (Mei sampai Juli), lalu turun menjadi 24,1% pada November 2024, 68,4% pada Desember 2024, dan 13,6% pada Januari 2025.

Kunjungan per bulan pada Juli sampai Desember 2024 bergerak di kisaran 165 sampai 197, sehingga kurvanya cenderung **mendatar sejak pertengahan 2024**.

**Implikasi:** pertumbuhan belum berhenti, tetapi tidak lagi secepat dua tahun sebelumnya. Perlu dipantau apakah tren mendatar ini berlanjut pada 2025.

**Batasan:** persentase pertumbuhan year-over-year otomatis mengecil karena basis tahun lalu makin besar, jadi sebagian perlambatan itu wajar. Kunjungan Januari 2025 (150) lebih rendah daripada Desember 2024 (197), tetapi itu **hanya satu bulan** dan belum cukup untuk menyimpulkan penurunan.

## 3. Bulan puncak: tergantung ukuran yang dipakai

- Menurut **revenue**, puncaknya **Juli 2024**: Rp 36.485.000 (191 kunjungan).
- Menurut **jumlah kunjungan**, puncaknya **Desember 2024**: 197 kunjungan (revenue Rp 36.115.000).

Selisih revenue kedua bulan itu hanya Rp 370.000 (sekitar 1%). Lima bulan teratas menurut kedua ukuran semuanya jatuh di **2024**.

**Implikasi:** tidak ada satu musim puncak yang jelas. Bulan-bulan tertinggi berkumpul di 2024 karena tren naik, bukan karena pola musiman tertentu.

**Batasan:** karena tren naik kuat, bulan-bulan terbaru hampir selalu menjadi yang tertinggi. Dengan data ini, musiman sejati tidak bisa dipisahkan dari tren pertumbuhan.

## 4. Hari dan jam: tidak ada yang menonjol secara berarti

Menurut hari, kunjungan tertinggi pada **Minggu (15,7%)** dan terendah pada **Selasa (13,4%)**, selisih 2,3 poin persentase. Menurut jam, sebarannya berkisar dari **10,4%** (pukul 12.00) sampai **11,7%** (pukul 15.00).

Uji chi-square tidak menemukan perbedaan yang signifikan, baik untuk hari (p = 0,108) maupun jam (p = 0,830), dengan ukuran efek sangat kecil (Cramér's V masing-masing 0,021 dan 0,012).

**Implikasi:** tidak ada dasar statistik untuk mengubah jadwal dokter atau jam praktik berdasarkan hari atau jam tertentu.

**Batasan:** uji hari memakai harapan yang disesuaikan dengan jumlah tiap hari kalender dalam periode data. Data tampak sintetis dengan sebaran yang hampir seragam, sehingga pola hari dan jam di data sungguhan bisa berbeda.

---

## Catatan untuk Analisis Berikutnya

Sebanyak 20% appointment tidak selesai (batal, no-show, dijadwal ulang). Dari tarif nominal Rp 920.790.000 pada seluruh appointment, Rp 184.355.000 (20%) tidak menjadi revenue. Ini menjadi bahan analisis no-show dan pembatalan berikutnya.

## Batasan Umum

- Revenue adalah **tarif nominal** appointment selesai, bukan pendapatan riil.
- Data 2021 (mulai 4 Juni) dan 2025 (hanya Januari) adalah **tahun parsial**.
- Data tampak **sintetis**, sehingga pola yang lemah tidak otomatis berarti pola itu tidak ada di klinik sungguhan.
- Analisis ini deskriptif. Tidak ada klaim sebab-akibat.

## Sumber Angka

| Angka | Sumber |
|---|---|
| Total kunjungan, revenue, status | `data/processed/monthly_trend.csv` dan query V9, V10 |
| Rata-rata per bulan, per tahun | Q2 (`03_visit_revenue_trend.sql`), atau dihitung dari `monthly_trend.csv` |
| Revenue per kunjungan per tahun | Total revenue dibagi total kunjungan per tahun, dari `monthly_trend.csv` |
| Year-over-year | Q5 |
| Laju pertumbuhan per bulan | Notebook `01_trend_analysis.ipynb`, bagian 7 (regresi pada log kunjungan) |
| Bulan puncak | Q3 |
| Persentase per hari dan jam | Q6 dan Q7 |
| Uji chi-square | Notebook `01_trend_analysis.ipynb`, bagian 10 |
