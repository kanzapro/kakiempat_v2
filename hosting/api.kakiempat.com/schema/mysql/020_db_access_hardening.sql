-- 020_db_access_hardening.sql
-- Jalankan di phpMyAdmin / MySQL sebagai user dengan hak GRANT (biasanya root cPanel).
-- Database bersama: kakiempa_v2 — hanya diakses API (localhost), bukan dari subdomain Flutter.

-- 1) User aplikasi: hanya dari localhost (shared hosting cPanel)
-- Ganti password sesuai .mysql_v2.php di server (jangan commit password).
-- CREATE USER IF NOT EXISTS 'kakiempa_v2_user'@'localhost' IDENTIFIED BY 'GANTI_PASSWORD_KUAT';

-- 2) Hak minimal — hanya schema kakiempa_v2
-- REVOKE ALL PRIVILEGES ON *.* FROM 'kakiempa_v2_user'@'localhost';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON `kakiempa_v2`.* TO 'kakiempa_v2_user'@'localhost';
-- FLUSH PRIVILEGES;

-- 3) Pastikan tidak ada user @'%' untuk akun aplikasi (hindari akses remote)
-- SELECT user, host FROM mysql.user WHERE user LIKE 'kakiempa_v2%';

-- 4) Charset konsisten
ALTER DATABASE `kakiempa_v2` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 5) Kapasitas koneksi simultan (opsional — sesuaikan limit cPanel)
--    6 subdomain Flutter hanya memanggil api.kakiempat.com; setiap worker PHP-FPM
--    memegang 1 koneksi MySQL. Pastikan max_connections > pm.max_children.
-- SET GLOBAL max_connections = 150;
-- SHOW VARIABLES LIKE 'max_connections';
-- SHOW GLOBAL STATUS LIKE 'Threads_connected';
