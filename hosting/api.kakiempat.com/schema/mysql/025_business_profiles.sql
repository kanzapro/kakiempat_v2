-- 025: Business partner tier (super-app merchant network)
-- Jalankan setelah 024_denpasar_kecamatan_mvp.sql

SET NAMES utf8mb4;

SET @kecamatan_enum := "ENUM('Denpasar Barat','Denpasar Timur','Denpasar Selatan','Denpasar Utara')";

CREATE TABLE IF NOT EXISTS `kakiempa_v2_business_profiles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `legal_name` VARCHAR(255) NOT NULL,
  `provider_type` ENUM('individual', 'business') NOT NULL DEFAULT 'business',
  `status` ENUM('draft', 'pending', 'approved', 'rejected') NOT NULL DEFAULT 'draft',
  `service_codes` JSON NULL COMMENT 'Array kode layanan yang ditawarkan',
  `verification_docs` JSON NULL,
  `submitted_at` TIMESTAMP(6) NULL,
  `approved_at` TIMESTAMP(6) NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_business_user` (`user_id`),
  KEY `idx_business_status` (`status`, `provider_type`),
  CONSTRAINT `fk_business_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_business_locations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `business_id` BIGINT UNSIGNED NOT NULL,
  `label` VARCHAR(128) NOT NULL DEFAULT 'Cabang utama',
  `address` TEXT NOT NULL,
  `kecamatan` ENUM('Denpasar Barat','Denpasar Timur','Denpasar Selatan','Denpasar Utara') NULL,
  `latitude` DECIMAL(10, 7) NULL,
  `longitude` DECIMAL(10, 7) NULL,
  `is_primary` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_business_loc_business` (`business_id`),
  KEY `idx_business_loc_kecamatan` (`kecamatan`),
  CONSTRAINT `fk_business_loc_profile` FOREIGN KEY (`business_id`)
    REFERENCES `kakiempa_v2_business_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tambah peran partner ke junction multi-role
SET @role_enum := (
  SELECT COLUMN_TYPE FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_user_roles'
    AND COLUMN_NAME = 'role'
  LIMIT 1
);
SET @ddl := IF(
  @role_enum IS NOT NULL AND @role_enum NOT LIKE '%partner%',
  "ALTER TABLE `kakiempa_v2_user_roles`
     MODIFY `role` ENUM('owner','sitter','admin','founder','partner') NOT NULL",
  'SELECT 1'
);
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('025_business_profiles.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
