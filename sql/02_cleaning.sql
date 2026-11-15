
-- ---------------------------------------------------------------------
-- 0. Hapus tabel bersih lama (urutan terbalik karena ada foreign key)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS diagnoses;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;


-- ---------------------------------------------------------------------
-- 1. doctors
-- ---------------------------------------------------------------------
CREATE TABLE doctors AS
SELECT
    TRIM(doctor_id)                          AS doctor_id,
    TRIM(name)                               AS name,
    TRIM(specialization)                     AS specialization,
    TRIM(schedule_days)                      AS schedule_days,
    NULLIF(TRIM(phone), '')                  AS phone,
    experience_years::INTEGER                AS experience_years,
    consultation_fee_idr::INTEGER            AS consultation_fee_idr
FROM raw_doctors;

ALTER TABLE doctors ADD PRIMARY KEY (doctor_id);


-- ---------------------------------------------------------------------
-- 2. patients
-- ---------------------------------------------------------------------
CREATE TABLE patients AS
SELECT
    TRIM(patient_id)                         AS patient_id,
    TRIM(name)                               AS name,
    NULLIF(TRIM(nik_masked), '')             AS nik_masked,
    dob::DATE                                AS dob,
    TRIM(gender)                             AS gender,
    NULLIF(TRIM(address), '')                AS address,
    TRIM(city)                               AS city,
    NULLIF(TRIM(phone), '')                  AS phone,
    COALESCE(NULLIF(TRIM(blood_type), ''), 'Tidak diketahui') AS blood_type,
    registration_date::DATE                  AS registration_date,
    TRIM(insurance_type)                     AS insurance_type
FROM raw_patients;

ALTER TABLE patients ADD PRIMARY KEY (patient_id);


-- ---------------------------------------------------------------------
-- 3. appointments
--    Tanggal diparse di CTE lebih dulu supaya kolom turunan bisa memakainya
-- ---------------------------------------------------------------------
CREATE TABLE appointments AS
WITH parsed AS (
    SELECT
        a.*,
        CASE
            WHEN TRIM(appt_date) ~ '^\d{4}-\d{2}-\d{2}$'
                THEN TO_DATE(TRIM(appt_date), 'YYYY-MM-DD')
            WHEN TRIM(appt_date) ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(TRIM(appt_date), 'DD/MM/YYYY')
            WHEN TRIM(appt_date) ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(TRIM(appt_date), 'DD-MM-YYYY')
            ELSE NULL
        END AS appt_date_clean
    FROM raw_appointments a
)
SELECT
    TRIM(appt_id)                            AS appt_id,
    TRIM(patient_id)                         AS patient_id,
    TRIM(doctor_id)                          AS doctor_id,
    appt_date_clean                          AS appt_date,
    TRIM(appt_time)::TIME                    AS appt_time,
    TRIM(complaint)                          AS complaint,
    TRIM(status)                             AS status,
    fee_idr::INTEGER                         AS fee_idr,
    TRIM(payment_method)                     AS payment_method,
    -- kolom turunan untuk analisis
    CASE WHEN TRIM(status) = 'completed'
         THEN fee_idr::INTEGER ELSE 0 END    AS revenue_idr,
    DATE_TRUNC('month', appt_date_clean)::DATE AS appt_month,
    EXTRACT(ISODOW FROM appt_date_clean)::INTEGER AS appt_dow,   -- 1=Senin ... 7=Minggu
    EXTRACT(HOUR FROM TRIM(appt_time)::TIME)::INTEGER AS appt_hour
FROM parsed;

ALTER TABLE appointments ADD PRIMARY KEY (appt_id);
ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients (patient_id);
ALTER TABLE appointments
    ADD CONSTRAINT fk_appt_doctor  FOREIGN KEY (doctor_id)  REFERENCES doctors (doctor_id);


-- ---------------------------------------------------------------------
-- 4. diagnoses
-- ---------------------------------------------------------------------
CREATE TABLE diagnoses AS
SELECT
    TRIM(diagnosis_id)                       AS diagnosis_id,
    TRIM(appt_id)                            AS appt_id,
    NULLIF(TRIM(icd_code), '')               AS icd_code,
    CASE WHEN NULLIF(TRIM(icd_code), '') IS NULL
         THEN 'Tidak terkode' ELSE 'Terkode' END AS icd_status,
    TRIM(description)                        AS description,
    TRIM(severity)                           AS severity,
    (TRIM(follow_up_required) = 'true')      AS follow_up_required,
    NULLIF(TRIM(notes), '')                  AS notes
FROM raw_diagnoses;

ALTER TABLE diagnoses ADD PRIMARY KEY (diagnosis_id);
-- UNIQUE memastikan satu appointment punya paling banyak satu diagnosis
ALTER TABLE diagnoses ADD CONSTRAINT uq_diag_appt UNIQUE (appt_id);
ALTER TABLE diagnoses
    ADD CONSTRAINT fk_diag_appt FOREIGN KEY (appt_id) REFERENCES appointments (appt_id);


-- ---------------------------------------------------------------------
-- 5. prescriptions
-- ---------------------------------------------------------------------
CREATE TABLE prescriptions AS
SELECT
    TRIM(rx_id)                              AS rx_id,
    TRIM(diagnosis_id)                       AS diagnosis_id,
    TRIM(patient_id)                         AS patient_id,
    TRIM(medicine_name)                      AS medicine_name,
    TRIM(dosage)                             AS dosage,
    TRIM(route)                              AS route,
    duration_days::INTEGER                   AS duration_days,
    CASE
        WHEN TRIM(prescribed_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TO_DATE(TRIM(prescribed_date), 'YYYY-MM-DD')
        WHEN TRIM(prescribed_date) ~ '^\d{2}/\d{2}/\d{4}$'
            THEN TO_DATE(TRIM(prescribed_date), 'DD/MM/YYYY')
        WHEN TRIM(prescribed_date) ~ '^\d{2}-\d{2}-\d{4}$'
            THEN TO_DATE(TRIM(prescribed_date), 'DD-MM-YYYY')
        ELSE NULL
    END                                      AS prescribed_date,
    quantity::INTEGER                        AS quantity
FROM raw_prescriptions;

ALTER TABLE prescriptions ADD PRIMARY KEY (rx_id);
ALTER TABLE prescriptions
    ADD CONSTRAINT fk_rx_diag    FOREIGN KEY (diagnosis_id) REFERENCES diagnoses (diagnosis_id);
ALTER TABLE prescriptions
    ADD CONSTRAINT fk_rx_patient FOREIGN KEY (patient_id)   REFERENCES patients (patient_id);


-- ---------------------------------------------------------------------
-- 6. Indeks untuk mempercepat JOIN dan filter pada analisis nanti
-- ---------------------------------------------------------------------
CREATE INDEX idx_appt_patient ON appointments (patient_id);
CREATE INDEX idx_appt_doctor  ON appointments (doctor_id);
CREATE INDEX idx_appt_date    ON appointments (appt_date);
CREATE INDEX idx_rx_diag      ON prescriptions (diagnosis_id);


-- ---------------------------------------------------------------------
-- 7. Perbarui statistik tabel (membantu planner query)
-- ---------------------------------------------------------------------
ANALYZE doctors;
ANALYZE patients;
ANALYZE appointments;
ANALYZE diagnoses;
ANALYZE prescriptions;