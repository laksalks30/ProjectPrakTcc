-- ============ FILE: database/auth_db.sql ============
-- Database: auth_db
-- DDL + Seed Data untuk Authentication Service

CREATE DATABASE IF NOT EXISTS auth_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE auth_db;

-- =============================================
-- Tabel: users
-- =============================================
DROP TABLE IF EXISTS token_blacklist;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user') NOT NULL DEFAULT 'user',
    phone VARCHAR(20) DEFAULT NULL,
    avatar_url VARCHAR(500) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Tabel: token_blacklist (untuk logout / blacklist JWT)
-- =============================================
CREATE TABLE token_blacklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_expires_at (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- Seed Data: 3 user dummy
-- Password untuk semua user: "password123"
-- Hash bcrypt dari "password123" (10 rounds)
-- =============================================
INSERT INTO users (name, email, password_hash, role, phone, avatar_url) VALUES
(
    'Admin Utama',
    'admin@obatlansia.com',
    '$2a$10$WJ6rEm1iyX7AbacCckwX7eLScB19LXy2KK3l/rWLeFzt2hYSSBD3O',
    'admin',
    '081234567890',
    NULL
),
(
    'Siti Nurhaliza',
    'siti.user@obatlansia.com',
    '$2a$10$WJ6rEm1iyX7AbacCckwX7eLScB19LXy2KK3l/rWLeFzt2hYSSBD3O',
    'user',
    '081234567891',
    NULL
),
(
    'Budi Santoso',
    'budi.user@obatlansia.com',
    '$2a$10$WJ6rEm1iyX7AbacCckwX7eLScB19LXy2KK3l/rWLeFzt2hYSSBD3O',
    'user',
    '081234567892',
    NULL
);
