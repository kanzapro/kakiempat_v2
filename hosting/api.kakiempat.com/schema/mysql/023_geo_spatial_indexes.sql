-- 023_geo_spatial_indexes.sql
-- Kolom koordinat terindeks untuk pencarian sitter/request terdekat (bounding box + haversine).
-- Jalankan via apply_v2_migration.php setelah 014_marketplace_booking_lifecycle.sql.

SET NAMES utf8mb4;

-- Sitter: denormalisasi lat/lng dari profile_json
SET @col_exists := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_sitter_profiles'
    AND COLUMN_NAME = 'latitude'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `kakiempa_v2_sitter_profiles`
     ADD COLUMN `latitude` DECIMAL(10, 7) NULL AFTER `profile_json`,
     ADD COLUMN `longitude` DECIMAL(10, 7) NULL AFTER `latitude`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `kakiempa_v2_sitter_profiles`
SET
  `latitude` = COALESCE(
    `latitude`,
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`profile_json`, '$.latitude')), 'null') AS DECIMAL(10, 7)),
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`profile_json`, '$.lat')), 'null') AS DECIMAL(10, 7))
  ),
  `longitude` = COALESCE(
    `longitude`,
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`profile_json`, '$.longitude')), 'null') AS DECIMAL(10, 7)),
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`profile_json`, '$.lng')), 'null') AS DECIMAL(10, 7)),
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`profile_json`, '$.lon')), 'null') AS DECIMAL(10, 7))
  )
WHERE `profile_json` IS NOT NULL
  AND (`latitude` IS NULL OR `longitude` IS NULL);

-- Request: denormalisasi lat/lng dari location_json
SET @col_exists := (
  SELECT COUNT(1) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_requests'
    AND COLUMN_NAME = 'latitude'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `kakiempa_v2_requests`
     ADD COLUMN `latitude` DECIMAL(10, 7) NULL AFTER `location_json`,
     ADD COLUMN `longitude` DECIMAL(10, 7) NULL AFTER `latitude`',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `kakiempa_v2_requests`
SET
  `latitude` = COALESCE(
    `latitude`,
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`location_json`, '$.latitude')), 'null') AS DECIMAL(10, 7)),
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`location_json`, '$.lat')), 'null') AS DECIMAL(10, 7))
  ),
  `longitude` = COALESCE(
    `longitude`,
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`location_json`, '$.longitude')), 'null') AS DECIMAL(10, 7)),
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`location_json`, '$.lng')), 'null') AS DECIMAL(10, 7)),
    CAST(NULLIF(JSON_UNQUOTE(JSON_EXTRACT(`location_json`, '$.lon')), 'null') AS DECIMAL(10, 7))
  )
WHERE `location_json` IS NOT NULL
  AND (`latitude` IS NULL OR `longitude` IS NULL);

-- Owner profiles: indeks geo (kolom sudah ada di 010)
SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_owner_profiles'
    AND INDEX_NAME = 'idx_v2_owner_geo'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_owner_profiles`
     ADD KEY `idx_v2_owner_geo` (`latitude`, `longitude`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Sitter: indeks status + koordinat (filter approved + bounding box)
SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_sitter_profiles'
    AND INDEX_NAME = 'idx_v2_sitter_geo'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_sitter_profiles`
     ADD KEY `idx_v2_sitter_geo` (`status`, `latitude`, `longitude`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Request: indeks status + layanan + koordinat
SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_requests'
    AND INDEX_NAME = 'idx_v2_requests_geo'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_requests`
     ADD KEY `idx_v2_requests_geo` (`status`, `service_code`, `latitude`, `longitude`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('023_geo_spatial_indexes.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
