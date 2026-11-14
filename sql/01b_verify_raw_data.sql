-- =========================================================
-- DATA QUALITY CHECKING
-- Tujuan:
-- Melakukan pemeriksaan kualitas data pada seluruh tabel
-- sebelum proses data cleaning dan transformasi dilakukan.
-- =========================================================


-- =========================================================
-- 1. PEMERIKSAAN NILAI KOSONG (MISSING VALUES)
-- =========================================================

SELECT 'patients.phone' AS kolom, COUNT(*) AS kosong
FROM raw_patients WHERE phone IS NULL OR phone = ''
UNION ALL
SELECT 'patients.blood_type', COUNT(*)
FROM raw_patients WHERE blood_type IS NULL OR blood_type = ''
UNION ALL
SELECT 'diagnoses.icd_code', COUNT(*)
FROM raw_diagnoses WHERE icd_code IS NULL OR icd_code = ''
UNION ALL
SELECT 'diagnoses.notes', COUNT(*)
FROM raw_diagnoses WHERE notes IS NULL OR notes = '';

-- =========================================================
-- 2. PEMERIKSAAN FORMAT TANGGAL TABEL APPOINTMENTS
-- =========================================================

SELECT
    CASE
        WHEN appt_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN appt_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN appt_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'DD-MM-YYYY'
        ELSE 'lainnya'
    END AS format_tanggal,
    COUNT(*) AS jumlah
FROM raw_appointments
GROUP BY 1
ORDER BY 2 DESC;

-- =========================================================
-- 3. PEMERIKSAAN FORMAT TANGGAL TABEL PRESCRIPTIONS
-- =========================================================


SELECT
    CASE
        WHEN prescribed_date ~ '^\d{4}-\d{2}-\d{2}$' THEN 'YYYY-MM-DD'
        WHEN prescribed_date ~ '^\d{2}/\d{2}/\d{4}$' THEN 'DD/MM/YYYY'
        WHEN prescribed_date ~ '^\d{2}-\d{2}-\d{4}$' THEN 'DD-MM-YYYY'
        ELSE 'lainnya'
    END AS format_tanggal,
    COUNT(*) AS jumlah
FROM raw_prescriptions
GROUP BY 1
ORDER BY 2 DESC;

-- =========================================================
-- 4. PEMERIKSAAN RELASI ANTAR TABEL (ORPHAN RECORDS)
-- =========================================================

SELECT 'appointments -> patients' AS relasi, COUNT(*) AS orphan
FROM raw_appointments a
LEFT JOIN raw_patients p ON p.patient_id = a.patient_id
WHERE p.patient_id IS NULL
UNION ALL
SELECT 'appointments -> doctors', COUNT(*)
FROM raw_appointments a
LEFT JOIN raw_doctors d ON d.doctor_id = a.doctor_id
WHERE d.doctor_id IS NULL
UNION ALL
SELECT 'diagnoses -> appointments', COUNT(*)
FROM raw_diagnoses g
LEFT JOIN raw_appointments a ON a.appt_id = g.appt_id
WHERE a.appt_id IS NULL
UNION ALL
SELECT 'prescriptions -> diagnoses', COUNT(*)
FROM raw_prescriptions r
LEFT JOIN raw_diagnoses g ON g.diagnosis_id = r.diagnosis_id
WHERE g.diagnosis_id IS NULL;

-- =========================================================
-- 5. PEMERIKSAAN DATA DUPLIKAT (DUPLICATE RECORDS)
-- =========================================================

SELECT 'doctors' AS tabel, COUNT(*) - COUNT(DISTINCT doctor_id) AS duplikat FROM raw_doctors
UNION ALL SELECT 'patients',      COUNT(*) - COUNT(DISTINCT patient_id)   FROM raw_patients
UNION ALL SELECT 'appointments',  COUNT(*) - COUNT(DISTINCT appt_id)      FROM raw_appointments
UNION ALL SELECT 'diagnoses',     COUNT(*) - COUNT(DISTINCT diagnosis_id) FROM raw_diagnoses
UNION ALL SELECT 'prescriptions', COUNT(*) - COUNT(DISTINCT rx_id)        FROM raw_prescriptions;

-- =========================================================
-- 6. PEMERIKSAAN DISTRIBUSI STATUS APPOINTMENT
-- =========================================================

SELECT status, COUNT(*) AS jumlah
FROM raw_appointments
GROUP BY status
ORDER BY jumlah DESC;