-- =====================================================================
-- 02b_verify_clean_data.sql
-- Tujuan : Memastikan hasil 02_cleaning.sql benar sebelum dipakai analisis
-- =====================================================================


-- V1. Jumlah baris tabel bersih harus sama dengan tabel mentah
-- Harapan: kolom selisih = 0 di semua baris
SELECT 'doctors' AS tabel,
       (SELECT COUNT(*) FROM raw_doctors)   AS raw,
       (SELECT COUNT(*) FROM doctors)       AS bersih,
       (SELECT COUNT(*) FROM raw_doctors) - (SELECT COUNT(*) FROM doctors) AS selisih
UNION ALL
SELECT 'patients',
       (SELECT COUNT(*) FROM raw_patients),
       (SELECT COUNT(*) FROM patients),
       (SELECT COUNT(*) FROM raw_patients) - (SELECT COUNT(*) FROM patients)
UNION ALL
SELECT 'appointments',
       (SELECT COUNT(*) FROM raw_appointments),
       (SELECT COUNT(*) FROM appointments),
       (SELECT COUNT(*) FROM raw_appointments) - (SELECT COUNT(*) FROM appointments)
UNION ALL
SELECT 'diagnoses',
       (SELECT COUNT(*) FROM raw_diagnoses),
       (SELECT COUNT(*) FROM diagnoses),
       (SELECT COUNT(*) FROM raw_diagnoses) - (SELECT COUNT(*) FROM diagnoses)
UNION ALL
SELECT 'prescriptions',
       (SELECT COUNT(*) FROM raw_prescriptions),
       (SELECT COUNT(*) FROM prescriptions),
       (SELECT COUNT(*) FROM raw_prescriptions) - (SELECT COUNT(*) FROM prescriptions);


-- V2. Tidak ada tanggal yang gagal dikonversi (NULL)
-- Harapan: 0 di semua baris
SELECT 'appointments.appt_date' AS kolom, COUNT(*) AS tanggal_null
FROM appointments WHERE appt_date IS NULL
UNION ALL
SELECT 'prescriptions.prescribed_date', COUNT(*)
FROM prescriptions WHERE prescribed_date IS NULL
UNION ALL
SELECT 'patients.dob', COUNT(*) FROM patients WHERE dob IS NULL
UNION ALL
SELECT 'patients.registration_date', COUNT(*)
FROM patients WHERE registration_date IS NULL;


-- V3. Rentang tanggal masuk akal
-- Harapan: appointments 2021-06-04 s.d. 2025-01-31
SELECT MIN(appt_date) AS tanggal_awal,
       MAX(appt_date) AS tanggal_akhir,
       COUNT(DISTINCT appt_month) AS jumlah_bulan
FROM appointments;


-- V4. Uji silang konversi tanggal: bandingkan teks asli dengan hasil
-- Ambil 3 contoh dari TIAP format. Periksa dengan mata:
--   03/05/2023 harus menjadi 2023-05-03 (3 Mei), BUKAN 2023-03-05
SELECT * FROM (
    SELECT 'YYYY-MM-DD' AS format_asli, r.appt_date AS teks_asli, a.appt_date AS hasil
    FROM raw_appointments r JOIN appointments a USING (appt_id)
    WHERE r.appt_date ~ '^\d{4}-\d{2}-\d{2}$' LIMIT 3
) x1
UNION ALL
SELECT * FROM (
    SELECT 'DD/MM/YYYY', r.appt_date, a.appt_date
    FROM raw_appointments r JOIN appointments a USING (appt_id)
    WHERE r.appt_date ~ '^\d{2}/\d{2}/\d{4}$' LIMIT 3
) x2
UNION ALL
SELECT * FROM (
    SELECT 'DD-MM-YYYY', r.appt_date, a.appt_date
    FROM raw_appointments r JOIN appointments a USING (appt_id)
    WHERE r.appt_date ~ '^\d{2}-\d{2}-\d{4}$' LIMIT 3
) x3;


-- V5. Bukti bahwa format garis miring dan strip adalah HARI-bulan
-- Harapan: kolom "angka_pertama_lebih_dari_12" > 0
--          kolom "angka_kedua_lebih_dari_12"   = 0
-- (kalau formatnya bulan-hari, yang kedua yang akan lebih dari 0)
SELECT
    COUNT(*) FILTER (WHERE SPLIT_PART(REPLACE(appt_date, '-', '/'), '/', 1)::INT > 12) AS angka_pertama_lebih_dari_12,
    COUNT(*) FILTER (WHERE SPLIT_PART(REPLACE(appt_date, '-', '/'), '/', 2)::INT > 12) AS angka_kedua_lebih_dari_12
FROM raw_appointments
WHERE appt_date ~ '^\d{2}[/-]\d{2}[/-]\d{4}$';


-- V6. Tanggal resep sama dengan tanggal appointment terkait
-- Harapan: selisih_tanggal = 0
SELECT COUNT(*) AS resep_total,
       COUNT(*) FILTER (WHERE p.prescribed_date <> a.appt_date) AS selisih_tanggal
FROM prescriptions p
JOIN diagnoses d    ON d.diagnosis_id = p.diagnosis_id
JOIN appointments a ON a.appt_id      = d.appt_id;


-- V7. Pasien pada resep sama dengan pasien pada appointment
-- Harapan: pasien_beda = 0
SELECT COUNT(*) FILTER (WHERE p.patient_id <> a.patient_id) AS pasien_beda
FROM prescriptions p
JOIN diagnoses d    ON d.diagnosis_id = p.diagnosis_id
JOIN appointments a ON a.appt_id      = d.appt_id;


-- V8. Appointment tidak terjadi sebelum pasien terdaftar
-- Harapan: 0
SELECT COUNT(*) AS appt_sebelum_registrasi
FROM appointments a
JOIN patients p USING (patient_id)
WHERE a.appt_date < p.registration_date;


-- V9. Revenue hanya dari status completed
-- Harapan: revenue_non_completed = 0
SELECT
    SUM(revenue_idr)                                         AS total_revenue_idr,
    SUM(revenue_idr) FILTER (WHERE status <> 'completed')    AS revenue_non_completed,
    SUM(fee_idr)                                             AS total_tarif_nominal_semua_status
FROM appointments;


-- V10. Status appointment dan jumlah revenue per status
-- Harapan: completed 4000 | cancelled 400 | no_show 350 | rescheduled 250
SELECT status, COUNT(*) AS jumlah, SUM(revenue_idr) AS revenue_idr
FROM appointments
GROUP BY status
ORDER BY jumlah DESC;


-- V11. Penanganan nilai kosong
-- Harapan: icd 698 'Tidak terkode' | blood 300 'Tidak diketahui' | phone 160
SELECT 'icd_status = Tidak terkode' AS cek, COUNT(*) AS jumlah
FROM diagnoses WHERE icd_status = 'Tidak terkode'
UNION ALL
SELECT 'blood_type = Tidak diketahui', COUNT(*)
FROM patients WHERE blood_type = 'Tidak diketahui'
UNION ALL
SELECT 'phone NULL', COUNT(*) FROM patients WHERE phone IS NULL;


-- V12. Kolom turunan waktu masuk akal
-- Harapan: appt_dow 1-7 (Senin-Minggu), appt_hour dalam jam praktik
SELECT MIN(appt_dow) AS dow_min, MAX(appt_dow) AS dow_max,
       MIN(appt_hour) AS jam_min, MAX(appt_hour) AS jam_max
FROM appointments;


-- V13. Kelengkapan diagnosis pada appointment completed
-- Harapan: completed_tanpa_diagnosis = 120 (dicatat di data_quality_log)
--          non_completed_dengan_diagnosis = 0
SELECT
    COUNT(*) FILTER (WHERE a.status = 'completed' AND d.diagnosis_id IS NULL) AS completed_tanpa_diagnosis,
    COUNT(*) FILTER (WHERE a.status <> 'completed' AND d.diagnosis_id IS NOT NULL) AS non_completed_dengan_diagnosis
FROM appointments a
LEFT JOIN diagnoses d USING (appt_id);


-- V14. Pasien tanpa appointment
-- Harapan: 169
SELECT COUNT(*) AS pasien_tanpa_kunjungan
FROM patients p
LEFT JOIN appointments a USING (patient_id)
WHERE a.appt_id IS NULL;


-- V15. Tipe data kolom tabel bersih (cek tipe sudah benar, bukan TEXT semua)
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('doctors', 'patients', 'appointments', 'diagnoses', 'prescriptions')
ORDER BY table_name, ordinal_position;