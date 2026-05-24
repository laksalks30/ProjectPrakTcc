-- ============ FILE: database/medication_db.sql ============
-- Database: medication_db
-- DDL + Seed Data untuk Medication Service

CREATE DATABASE IF NOT EXISTS medication_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE medication_db;

-- =============================================
-- Drop tables in reverse dependency order
-- =============================================
DROP TABLE IF EXISTS medication_logs;
DROP TABLE IF EXISTS reminders;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS patients;

-- =============================================
-- Tabel: patients (Data Lansia)
-- =============================================
CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT DEFAULT NULL COMMENT 'FK ke users di auth_db (opsional)',
    name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    gender ENUM('male', 'female') NOT NULL,
    address TEXT DEFAULT NULL,
    blood_type ENUM('A', 'B', 'AB', 'O') DEFAULT NULL,
    photo_url VARCHAR(500) DEFAULT NULL,
    medical_notes TEXT DEFAULT NULL,
    caregiver_id INT DEFAULT NULL COMMENT 'FK ke users di auth_db',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_caregiver_id (caregiver_id),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Tabel: medications (Master Data Obat)
-- =============================================
CREATE TABLE medications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    generic_name VARCHAR(150) DEFAULT NULL,
    category VARCHAR(100) DEFAULT NULL,
    description TEXT DEFAULT NULL,
    photo_url VARCHAR(500) DEFAULT NULL,
    unit VARCHAR(50) NOT NULL DEFAULT 'tablet',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_name (name),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Tabel: prescriptions (Resep Obat)
-- =============================================
CREATE TABLE prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    medication_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL COMMENT 'e.g. 3x sehari',
    start_date DATE NOT NULL,
    end_date DATE DEFAULT NULL,
    doctor_name VARCHAR(100) DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    status ENUM('active', 'completed', 'stopped') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE,
    INDEX idx_patient_id (patient_id),
    INDEX idx_medication_id (medication_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Tabel: reminders (Jadwal Pengingat)
-- =============================================
CREATE TABLE reminders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    patient_id INT NOT NULL,
    scheduled_time TIME NOT NULL,
    days_of_week JSON DEFAULT NULL COMMENT '["monday","tuesday",...]',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notes VARCHAR(255) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    INDEX idx_prescription_id (prescription_id),
    INDEX idx_patient_id (patient_id),
    INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Tabel: medication_logs (Log Minum Obat)
-- =============================================
CREATE TABLE medication_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reminder_id INT DEFAULT NULL,
    patient_id INT NOT NULL,
    prescription_id INT NOT NULL,
    scheduled_at DATETIME NOT NULL,
    taken_at DATETIME DEFAULT NULL,
    status ENUM('taken', 'missed', 'skipped', 'late') NOT NULL DEFAULT 'taken',
    notes TEXT DEFAULT NULL,
    logged_by INT DEFAULT NULL COMMENT 'user_id yang mencatat',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reminder_id) REFERENCES reminders(id) ON DELETE SET NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON DELETE CASCADE,
    INDEX idx_patient_id (patient_id),
    INDEX idx_prescription_id (prescription_id),
    INDEX idx_status (status),
    INDEX idx_scheduled_at (scheduled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Seed Data: 5 Lansia Dummy
-- =============================================
INSERT INTO patients (user_id, name, birth_date, gender, address, blood_type, photo_url, medical_notes, caregiver_id) VALUES
(3, 'Haji Sudirman', '1945-08-17', 'male', 'Jl. Merdeka No. 45, Jakarta Pusat', 'A', NULL, 'Riwayat hipertensi dan diabetes tipe 2. Alergi terhadap penisilin.', 2),
(3, 'Ibu Kartini', '1950-04-21', 'female', 'Jl. Pahlawan No. 12, Bandung', 'B', NULL, 'Osteoporosis stadium 2. Riwayat operasi katarak mata kiri.', 2),
(3, 'Kakek Habibie', '1948-06-25', 'male', 'Jl. Teknologi No. 88, Surabaya', 'O', NULL, 'Penyakit jantung koroner. Menggunakan pacemaker sejak 2020.', 2),
(3, 'Nenek Fatimah', '1952-12-01', 'female', 'Jl. Melati No. 7, Yogyakarta', 'AB', NULL, 'Asma kronis. Riwayat stroke ringan tahun 2022.', 2),
(3, 'Mbah Suroto', '1940-03-15', 'male', 'Jl. Kenanga No. 23, Semarang', 'A', NULL, 'Diabetes tipe 2, gangguan ginjal stadium awal. Diet rendah garam.', 2);

-- =============================================
-- Seed Data: 10 Obat Dummy
-- =============================================
INSERT INTO medications (name, generic_name, category, description, photo_url, unit) VALUES
('Amlodipine 5mg', 'Amlodipine Besylate', 'Antihipertensi', 'Obat untuk menurunkan tekanan darah tinggi. Bekerja dengan melemaskan pembuluh darah.', NULL, 'tablet'),
('Metformin 500mg', 'Metformin HCl', 'Antidiabetes', 'Obat diabetes tipe 2 yang membantu mengontrol kadar gula darah.', NULL, 'tablet'),
('Simvastatin 20mg', 'Simvastatin', 'Antihiperlipidemia', 'Menurunkan kadar kolesterol dan trigliserida dalam darah.', NULL, 'tablet'),
('Omeprazole 20mg', 'Omeprazole', 'Antasida/PPI', 'Mengurangi produksi asam lambung. Untuk GERD dan tukak lambung.', NULL, 'kapsul'),
('Aspirin 80mg', 'Acetylsalicylic Acid', 'Antiplatelet', 'Pengencer darah dosis rendah untuk pencegahan serangan jantung dan stroke.', NULL, 'tablet'),
('Captopril 25mg', 'Captopril', 'ACE Inhibitor', 'Obat tekanan darah tinggi dan gagal jantung. Diminum sebelum makan.', NULL, 'tablet'),
('Glimepiride 2mg', 'Glimepiride', 'Antidiabetes', 'Merangsang pankreas untuk memproduksi lebih banyak insulin.', NULL, 'tablet'),
('Salbutamol Inhaler', 'Salbutamol Sulfate', 'Bronkodilator', 'Inhaler untuk melegakan sesak napas pada penderita asma.', NULL, 'puff'),
('Clopidogrel 75mg', 'Clopidogrel Bisulfate', 'Antiplatelet', 'Mencegah penggumpalan darah pada penderita penyakit jantung.', NULL, 'tablet'),
('Calcium + Vit D3', 'Kalsium Karbonat + Cholecalciferol', 'Suplemen', 'Suplemen tulang untuk pencegahan dan pengobatan osteoporosis.', NULL, 'tablet');

-- =============================================
-- Seed Data: Resep Obat
-- =============================================
INSERT INTO prescriptions (patient_id, medication_id, dosage, frequency, start_date, end_date, doctor_name, notes, status) VALUES
(1, 1, '1 tablet', '1x sehari (pagi)', '2025-01-01', '2025-12-31', 'dr. Ahmad Yani, Sp.PD', 'Diminum pagi hari sebelum makan. Monitor tekanan darah rutin.', 'active'),
(1, 2, '1 tablet', '2x sehari (pagi & malam)', '2025-01-01', '2025-12-31', 'dr. Ahmad Yani, Sp.PD', 'Diminum sesudah makan. Cek gula darah setiap minggu.', 'active'),
(2, 10, '1 tablet', '1x sehari (malam)', '2025-02-01', '2025-08-01', 'dr. Siti Rahayu, Sp.OT', 'Diminum setelah makan malam dengan segelas air putih.', 'active'),
(3, 5, '1 tablet', '1x sehari (pagi)', '2025-01-15', '2025-12-31', 'dr. Budi Karya, Sp.JP', 'Diminum setelah makan pagi. Jangan dikombinasi dengan ibuprofen.', 'active'),
(3, 9, '1 tablet', '1x sehari (malam)', '2025-01-15', '2025-12-31', 'dr. Budi Karya, Sp.JP', 'Diminum malam hari. Hindari alkohol.', 'active'),
(4, 8, '2 puff', '3x sehari atau saat sesak', '2025-03-01', NULL, 'dr. Rina Susanti, Sp.P', 'Kocok inhaler sebelum digunakan. Kumur setelah pemakaian.', 'active'),
(5, 2, '1 tablet', '3x sehari', '2025-01-01', '2025-12-31', 'dr. Ahmad Yani, Sp.PD', 'Diminum 30 menit sebelum makan. Pantau fungsi ginjal.', 'active'),
(5, 6, '1 tablet', '2x sehari', '2025-01-01', '2025-12-31', 'dr. Ahmad Yani, Sp.PD', 'Diminum 1 jam sebelum makan. Monitor tekanan darah.', 'active');

-- =============================================
-- Seed Data: Reminders
-- =============================================
INSERT INTO reminders (prescription_id, patient_id, scheduled_time, days_of_week, is_active, notes) VALUES
(1, 1, '07:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Amlodipine pagi - Pak Sudirman'),
(2, 1, '07:30:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Metformin pagi - Pak Sudirman'),
(2, 1, '19:30:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Metformin malam - Pak Sudirman'),
(3, 2, '20:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Calcium malam - Ibu Kartini'),
(4, 3, '07:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Aspirin pagi - Kakek Habibie'),
(5, 3, '20:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Clopidogrel malam - Kakek Habibie'),
(6, 4, '08:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Salbutamol pagi - Nenek Fatimah'),
(6, 4, '14:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Salbutamol siang - Nenek Fatimah'),
(6, 4, '20:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Salbutamol malam - Nenek Fatimah'),
(7, 5, '06:30:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Metformin pagi - Mbah Suroto'),
(7, 5, '12:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Metformin siang - Mbah Suroto'),
(7, 5, '18:00:00', '["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]', TRUE, 'Metformin malam - Mbah Suroto');

-- =============================================
-- Seed Data: Medication Logs
-- =============================================
INSERT INTO medication_logs (reminder_id, patient_id, prescription_id, scheduled_at, taken_at, status, notes, logged_by) VALUES
(1, 1, 1, '2025-05-17 07:00:00', '2025-05-17 07:05:00', 'taken', 'Diminum tepat waktu', 2),
(2, 1, 2, '2025-05-17 07:30:00', '2025-05-17 07:35:00', 'taken', 'Diminum setelah sarapan', 2),
(3, 1, 2, '2025-05-17 19:30:00', '2025-05-17 20:10:00', 'late', 'Terlambat 40 menit, lupa', 2),
(4, 2, 3, '2025-05-17 20:00:00', '2025-05-17 20:00:00', 'taken', NULL, 2),
(5, 3, 4, '2025-05-17 07:00:00', NULL, 'missed', 'Pasien menolak minum obat', 2),
(6, 3, 5, '2025-05-17 20:00:00', '2025-05-17 20:15:00', 'taken', NULL, 2),
(7, 4, 6, '2025-05-17 08:00:00', '2025-05-17 08:00:00', 'taken', '2 puff diberikan', 2),
(8, 4, 6, '2025-05-17 14:00:00', NULL, 'skipped', 'Pasien tidak sesak, skip dosis siang', 2),
(10, 5, 7, '2025-05-17 06:30:00', '2025-05-17 06:30:00', 'taken', NULL, 2),
(11, 5, 7, '2025-05-17 12:00:00', '2025-05-17 12:30:00', 'late', 'Terlambat 30 menit', 2),
(1, 1, 1, '2025-05-16 07:00:00', '2025-05-16 07:10:00', 'taken', NULL, 2),
(2, 1, 2, '2025-05-16 07:30:00', '2025-05-16 07:30:00', 'taken', NULL, 2),
(3, 1, 2, '2025-05-16 19:30:00', '2025-05-16 19:30:00', 'taken', NULL, 2),
(5, 3, 4, '2025-05-16 07:00:00', '2025-05-16 07:00:00', 'taken', NULL, 2),
(6, 3, 5, '2025-05-16 20:00:00', '2025-05-16 20:00:00', 'taken', NULL, 2),
(7, 4, 6, '2025-05-16 08:00:00', '2025-05-16 08:05:00', 'taken', NULL, 2),
(10, 5, 7, '2025-05-16 06:30:00', NULL, 'missed', 'Pasien masih tidur', 2),
(11, 5, 7, '2025-05-16 12:00:00', '2025-05-16 12:00:00', 'taken', NULL, 2),
(12, 5, 7, '2025-05-16 18:00:00', '2025-05-16 18:00:00', 'taken', NULL, 2);
