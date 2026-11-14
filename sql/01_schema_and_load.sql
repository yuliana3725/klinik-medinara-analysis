-- ========================================================
-- 1. DROP TABLE
-- Menghapus tabel lama jika tabel tersebut sudah tersedia.
-- IF EXISTS mencegah error jika tabel belum pernah dibuat.
-- CATATAN: Seluruh data dalam tabel yang dihapus akan hilang.
-- ========================================================
	
DROP TABLE IF EXISTS raw_prescriptions;
DROP TABLE IF EXISTS raw_diagnoses;
DROP TABLE IF EXISTS raw_appointments;
DROP TABLE IF EXISTS raw_patients;
DROP TABLE IF EXISTS raw_doctors;

-- ========================================================
-- 2. CREATE TABLE
-- Membuat lima tabel untuk menyimpan data mentah klinik.
-- TEXT digunakan agar data mentah dapat ditampung terlebih
-- dahulu sebelum dilakukan validasi dan konversi tipe data.
-- ========================================================

CREATE TABLE raw_doctors (
    doctor_id            TEXT,
    name                 TEXT,
    specialization       TEXT,
    schedule_days        TEXT,
    phone                TEXT,
    experience_years     TEXT,
    consultation_fee_idr TEXT
);

CREATE TABLE raw_patients (
    patient_id        TEXT,
    name              TEXT,
    nik_masked        TEXT,
    dob               TEXT,
    gender            TEXT,
    address           TEXT,
    city              TEXT,
    phone             TEXT,
    blood_type        TEXT,
    registration_date TEXT,
    insurance_type    TEXT
);

CREATE TABLE raw_appointments (
    appt_id        TEXT,
    patient_id     TEXT,
    doctor_id      TEXT,
    appt_date      TEXT,
    appt_time      TEXT,
    complaint      TEXT,
    status         TEXT,
    fee_idr        TEXT,
    payment_method TEXT
);

CREATE TABLE raw_diagnoses (
    diagnosis_id       TEXT,
    appt_id            TEXT,
    icd_code           TEXT,
    description        TEXT,
    severity           TEXT,
    follow_up_required TEXT,
    notes              TEXT
);

CREATE TABLE raw_prescriptions (
    rx_id           TEXT,
    diagnosis_id    TEXT,
    patient_id      TEXT,
    medicine_name   TEXT,
    dosage          TEXT,
    route           TEXT,
    duration_days   TEXT,
    prescribed_date TEXT,
    quantity        TEXT
);

-- ========================================================
-- 3. IMPORT CSV
-- Memasukkan data dari file CSV ke masing-masing raw table.
-- Proses import dilakukan melalui fitur Import/Export Data
-- pada pgAdmin.
--
-- CATATAN:
-- Bagian ini merupakan dokumentasi tahapan import.
-- Perintah SELECT di bawah tidak melakukan import data.
-- ========================================================

-- ========================================================
-- 4. DATA VALIDATION
-- Memeriksa jumlah baris pada setiap tabel setelah import.
-- COUNT(*) digunakan untuk menghitung seluruh baris data.
-- ========================================================
SELECT COUNT(*) FROM raw_appointments;
SELECT * FROM raw_appointments LIMIT 5;

SELECT COUNT(*) FROM raw_diagnoses;
SELECT COUNT(*) FROM raw_doctors;
SELECT COUNT(*) FROM raw_patients;
SELECT * FROM raw_patients LIMIT 5;
SELECT COUNT(*) FROM raw_prescriptions;