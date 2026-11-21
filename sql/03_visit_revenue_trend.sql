-- =====================================================================
-- 03_visit_revenue_trend.sql
-- Proyek : Klinik Medinara Analysis
-- Pertanyaan bisnis 1:
--   Bagaimana tren kunjungan dan pendapatan per bulan? Kapan puncaknya?
--   Hari dan jam apa yang paling ramai?
--
-- Definisi (tulis juga di README):
--   Kunjungan  = appointment berstatus 'completed'
--   Revenue    = jumlah tarif appointment 'completed' (kolom revenue_idr).
--                Ini TARIF NOMINAL, bukan pendapatan riil.
--   Total appt = semua status (completed, cancelled, no_show, rescheduled)
--
-- Peringatan data:
--   * Juni 2021 hanya mulai 4 Juni, jadi bulan itu tidak penuh.
--   * Data berhenti 31 Januari 2025, jadi 2021 dan 2025 hanya tahun parsial.
--     Bandingkan tahun lewat RATA-RATA PER BULAN, bukan total.
-- =====================================================================


-- ---------------------------------------------------------------------
-- V1. Tren bulanan: kunjungan, revenue, rata-rata biaya, pertumbuhan MoM
--     Teknik: CTE, LAG(), AVG() OVER (window frame)
-- ---------------------------------------------------------------------
WITH bulanan AS (
    SELECT
        appt_month,
        COUNT(*)                                        AS total_appt,
        COUNT(*) FILTER (WHERE status = 'completed')    AS kunjungan,
        COUNT(*) FILTER (WHERE status = 'cancelled')    AS cancelled,
        COUNT(*) FILTER (WHERE status = 'no_show')      AS no_show,
        COUNT(*) FILTER (WHERE status = 'rescheduled')  AS rescheduled,
        SUM(revenue_idr)                                AS revenue_idr
    FROM appointments
    GROUP BY appt_month
)
SELECT
    appt_month,
    total_appt,
    kunjungan,
    cancelled,
    no_show,
    rescheduled,
    revenue_idr,
    ROUND(revenue_idr::NUMERIC / NULLIF(kunjungan, 0))              AS rata_rata_per_kunjungan,
    -- pertumbuhan dibanding bulan sebelumnya (%)
    ROUND(100.0 * (kunjungan - LAG(kunjungan) OVER (ORDER BY appt_month))
          / NULLIF(LAG(kunjungan) OVER (ORDER BY appt_month), 0), 1) AS mom_kunjungan_pct,
    ROUND(100.0 * (revenue_idr - LAG(revenue_idr) OVER (ORDER BY appt_month))
          / NULLIF(LAG(revenue_idr) OVER (ORDER BY appt_month), 0), 1) AS mom_revenue_pct,
    -- rata-rata bergerak 3 bulan untuk meredam fluktuasi
    ROUND(AVG(kunjungan) OVER (ORDER BY appt_month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1)             AS rata_bergerak_3bln
FROM bulanan
ORDER BY appt_month;


-- ---------------------------------------------------------------------
-- V2. Ringkasan per tahun (bandingkan lewat rata-rata per bulan)
-- ---------------------------------------------------------------------
WITH bulanan AS (
    SELECT
        EXTRACT(YEAR FROM appt_month)::INT              AS tahun,
        appt_month,
        COUNT(*) FILTER (WHERE status = 'completed')    AS kunjungan,
        SUM(revenue_idr)                                AS revenue_idr
    FROM appointments
    GROUP BY 1, 2
)
SELECT
    tahun,
    COUNT(*)                                            AS jumlah_bulan_data,
    SUM(kunjungan)                                      AS total_kunjungan,
    SUM(revenue_idr)                                    AS total_revenue_idr,
    ROUND(AVG(kunjungan), 1)                            AS rata_kunjungan_per_bulan,
    ROUND(AVG(revenue_idr))                             AS rata_revenue_per_bulan,
    ROUND(100.0 * (AVG(kunjungan) - LAG(AVG(kunjungan)) OVER (ORDER BY tahun))
          / NULLIF(LAG(AVG(kunjungan)) OVER (ORDER BY tahun), 0), 1) AS pertumbuhan_rata_kunjungan_pct
FROM bulanan
GROUP BY tahun
ORDER BY tahun;


-- ---------------------------------------------------------------------
-- V3. Bulan puncak: 5 bulan tertinggi menurut revenue dan menurut kunjungan
--     Teknik: RANK()
-- ---------------------------------------------------------------------
WITH bulanan AS (
    SELECT
        appt_month,
        COUNT(*) FILTER (WHERE status = 'completed') AS kunjungan,
        SUM(revenue_idr)                             AS revenue_idr
    FROM appointments
    GROUP BY appt_month
),
peringkat AS (
    SELECT
        appt_month, kunjungan, revenue_idr,
        RANK() OVER (ORDER BY revenue_idr DESC) AS rank_revenue,
        RANK() OVER (ORDER BY kunjungan  DESC)  AS rank_kunjungan
    FROM bulanan
)
SELECT *
FROM peringkat
WHERE rank_revenue <= 5 OR rank_kunjungan <= 5
ORDER BY rank_revenue;


-- ---------------------------------------------------------------------
-- V4. Pola musiman: rata-rata kunjungan per bulan kalender
--     Hanya tahun penuh 2022, 2023, 2024 agar adil (2021 dan 2025 parsial)
-- ---------------------------------------------------------------------
WITH bulanan AS (
    SELECT
        appt_month,
        EXTRACT(YEAR  FROM appt_month)::INT             AS tahun,
        EXTRACT(MONTH FROM appt_month)::INT             AS bulan,
        COUNT(*) FILTER (WHERE status = 'completed')    AS kunjungan,
        SUM(revenue_idr)                                AS revenue_idr
    FROM appointments
    WHERE appt_month BETWEEN DATE '2022-01-01' AND DATE '2024-12-01'
    GROUP BY appt_month
)
SELECT
    bulan,
    TO_CHAR(TO_DATE(bulan::TEXT, 'MM'), 'Mon')          AS nama_bulan,
    ROUND(AVG(kunjungan), 1)                            AS rata_kunjungan,
    ROUND(AVG(revenue_idr))                             AS rata_revenue
FROM bulanan
GROUP BY bulan
ORDER BY bulan;


-- ---------------------------------------------------------------------
-- V5. Pertumbuhan year-over-year per bulan (dibanding bulan yang sama tahun lalu)
-- ---------------------------------------------------------------------
WITH bulanan AS (
    SELECT
        appt_month,
        COUNT(*) FILTER (WHERE status = 'completed') AS kunjungan,
        SUM(revenue_idr)                             AS revenue_idr
    FROM appointments
    GROUP BY appt_month
)
SELECT
    b.appt_month,
    b.kunjungan,
    p.kunjungan                                                    AS kunjungan_tahun_lalu,
    ROUND(100.0 * (b.kunjungan - p.kunjungan) / NULLIF(p.kunjungan, 0), 1)       AS yoy_kunjungan_pct,
    b.revenue_idr,
    p.revenue_idr                                                  AS revenue_tahun_lalu,
    ROUND(100.0 * (b.revenue_idr - p.revenue_idr) / NULLIF(p.revenue_idr, 0), 1) AS yoy_revenue_pct
FROM bulanan b
JOIN bulanan p ON p.appt_month = (b.appt_month - INTERVAL '1 year')::DATE
ORDER BY b.appt_month;


-- ---------------------------------------------------------------------
-- V6. Kunjungan menurut hari dalam seminggu
--     appt_dow: 1 = Senin ... 7 = Minggu
-- ---------------------------------------------------------------------
SELECT
    appt_dow,
    CASE appt_dow
        WHEN 1 THEN 'Senin'  WHEN 2 THEN 'Selasa' WHEN 3 THEN 'Rabu'
        WHEN 4 THEN 'Kamis'  WHEN 5 THEN 'Jumat'  WHEN 6 THEN 'Sabtu'
        WHEN 7 THEN 'Minggu'
    END                                                           AS hari,
    COUNT(*)                                                      AS total_appt,
    COUNT(*) FILTER (WHERE status = 'completed')                  AS kunjungan,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'completed')
          / SUM(COUNT(*) FILTER (WHERE status = 'completed')) OVER (), 1) AS persen_kunjungan,
    SUM(revenue_idr)                                              AS revenue_idr
FROM appointments
GROUP BY appt_dow
ORDER BY appt_dow;


-- ---------------------------------------------------------------------
-- V7. Kunjungan menurut jam
-- ---------------------------------------------------------------------
SELECT
    appt_hour                                                     AS jam,
    COUNT(*)                                                      AS total_appt,
    COUNT(*) FILTER (WHERE status = 'completed')                  AS kunjungan,
    ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'completed')
          / SUM(COUNT(*) FILTER (WHERE status = 'completed')) OVER (), 1) AS persen_kunjungan
FROM appointments
GROUP BY appt_hour
ORDER BY appt_hour;


-- ---------------------------------------------------------------------
-- V8. Peta panas hari x jam (jumlah kunjungan completed)
--     Hasilnya bisa dibuat heatmap di Python atau dashboard
-- ---------------------------------------------------------------------
SELECT
    appt_hour AS jam,
    COUNT(*) FILTER (WHERE appt_dow = 1) AS senin,
    COUNT(*) FILTER (WHERE appt_dow = 2) AS selasa,
    COUNT(*) FILTER (WHERE appt_dow = 3) AS rabu,
    COUNT(*) FILTER (WHERE appt_dow = 4) AS kamis,
    COUNT(*) FILTER (WHERE appt_dow = 5) AS jumat,
    COUNT(*) FILTER (WHERE appt_dow = 6) AS sabtu,
    COUNT(*) FILTER (WHERE appt_dow = 7) AS minggu
FROM appointments
WHERE status = 'completed'
GROUP BY appt_hour
ORDER BY appt_hour;


-- ---------------------------------------------------------------------
-- V9. Tabel ringkas untuk dashboard (ekspor ke data/processed/monthly_trend.csv)
--     Di pgAdmin: jalankan query, lalu klik ikon "Download as CSV" di toolbar
--     tab Data Output. Data ini agregat, aman dipublikasikan.
-- ---------------------------------------------------------------------
SELECT
    appt_month                                      AS bulan,
    COUNT(*)                                        AS total_appt,
    COUNT(*) FILTER (WHERE status = 'completed')    AS kunjungan,
    COUNT(*) FILTER (WHERE status = 'cancelled')    AS cancelled,
    COUNT(*) FILTER (WHERE status = 'no_show')      AS no_show,
    COUNT(*) FILTER (WHERE status = 'rescheduled')  AS rescheduled,
    SUM(revenue_idr)                                AS revenue_idr
FROM appointments
GROUP BY appt_month
ORDER BY appt_month;