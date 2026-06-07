-- 024_denpasar_kecamatan_mvp.sql
-- Hyperlocal MVP: filter marketplace per kecamatan Kota Denpasar (tanpa radius GPS).
-- Jalankan via apply_v2_migration.php setelah 023_geo_spatial_indexes.sql.

SET NAMES utf8mb4;

SET @kecamatan_enum := "ENUM('Denpasar Barat','Denpasar Timur','Denpasar Selatan','Denpasar Utara')";

-- Sitter profiles
SET @col_exists := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_sitter_profiles'
    AND COLUMN_NAME = 'kecamatan'
);
SET @ddl := IF(@col_exists = 0,
  CONCAT('ALTER TABLE `kakiempa_v2_sitter_profiles`
     ADD COLUMN `kecamatan` ', @kecamatan_enum, ' NULL AFTER `address`'),
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `kakiempa_v2_sitter_profiles`
SET `kecamatan` = 'Denpasar Selatan'
WHERE `kecamatan` IS NULL;

SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_sitter_profiles'
    AND INDEX_NAME = 'idx_v2_sitter_kecamatan'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_sitter_profiles` ADD INDEX `idx_v2_sitter_kecamatan` (`kecamatan`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Owner profiles
SET @col_exists := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_owner_profiles'
    AND COLUMN_NAME = 'kecamatan'
);
SET @ddl := IF(@col_exists = 0,
  CONCAT('ALTER TABLE `kakiempa_v2_owner_profiles`
     ADD COLUMN `kecamatan` ', @kecamatan_enum, ' NULL AFTER `home_address`'),
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `kakiempa_v2_owner_profiles`
SET `kecamatan` = 'Denpasar Selatan'
WHERE `kecamatan` IS NULL;

SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_owner_profiles'
    AND INDEX_NAME = 'idx_v2_owner_kecamatan'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_owner_profiles` ADD INDEX `idx_v2_owner_kecamatan` (`kecamatan`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Marketplace requests (bookings)
SET @col_exists := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_requests'
    AND COLUMN_NAME = 'kecamatan'
);
SET @ddl := IF(@col_exists = 0,
  CONCAT('ALTER TABLE `kakiempa_v2_requests`
     ADD COLUMN `kecamatan` ', @kecamatan_enum, ' NULL AFTER `location_json`'),
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `kakiempa_v2_requests`
SET `kecamatan` = 'Denpasar Selatan'
WHERE `kecamatan` IS NULL;

SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_requests'
    AND INDEX_NAME = 'idx_v2_requests_kecamatan'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_requests`
     ADD INDEX `idx_v2_requests_kecamatan` (`kecamatan`, `status`, `service_code`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
