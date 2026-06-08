-- 026: Platform API — partner app registry, scoped keys, event outbox (super-app open platform)
-- Jalankan setelah 025_business_profiles.sql

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_partner_apps` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(32) NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `api_key_hash` CHAR(64) NOT NULL COMMENT 'SHA-256 hex of raw API key',
  `webhook_secret` VARCHAR(64) NOT NULL,
  `webhook_url` VARCHAR(512) NULL,
  `allowed_scopes` JSON NULL COMMENT 'e.g. ["booking.read","pet.read","webhook.receive"]',
  `is_active` TINYINT(1) NOT NULL DEFAULT 0,
  `approved_by` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_partner_app_code` (`code`),
  KEY `idx_partner_app_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_platform_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `partner_app_id` INT UNSIGNED NULL,
  `event_type` VARCHAR(64) NOT NULL,
  `payload_json` JSON NOT NULL,
  `delivery_status` ENUM('pending', 'delivered', 'failed') NOT NULL DEFAULT 'pending',
  `attempts` INT UNSIGNED NOT NULL DEFAULT 0,
  `last_error` VARCHAR(512) NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `delivered_at` TIMESTAMP(6) NULL,
  PRIMARY KEY (`id`),
  KEY `idx_platform_events_pending` (`delivery_status`, `created_at`),
  KEY `idx_platform_events_type` (`event_type`),
  CONSTRAINT `fk_platform_event_app` FOREIGN KEY (`partner_app_id`)
    REFERENCES `kakiempa_v2_partner_apps` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('026_platform_api.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
