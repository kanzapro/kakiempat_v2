-- Security hardening: rate limits, security audit log, refresh tokens

CREATE TABLE IF NOT EXISTS `kakiempa_rate_limits` (
  `rate_key` VARCHAR(128) NOT NULL,
  `attempt_count` INT UNSIGNED NOT NULL DEFAULT 1,
  `window_start` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`rate_key`),
  KEY `idx_rate_limits_window` (`window_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kakiempa_security_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `event_type` VARCHAR(64) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_id` BIGINT UNSIGNED NULL,
  `details` JSON NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_security_log_type` (`event_type`),
  KEY `idx_security_log_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `kakiempa_v2_sessions`
  ADD COLUMN IF NOT EXISTS `refresh_token_hash` CHAR(64) NULL AFTER `expires_at`,
  ADD COLUMN IF NOT EXISTS `refresh_expires_at` TIMESTAMP(6) NULL AFTER `refresh_token_hash`;

-- Index refresh_token_hash (skip jika sudah ada)
SET @idx_exists := (
  SELECT COUNT(1) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_sessions'
    AND INDEX_NAME = 'idx_v2_sessions_refresh'
);
SET @ddl := IF(@idx_exists = 0,
  'ALTER TABLE `kakiempa_v2_sessions` ADD KEY `idx_v2_sessions_refresh` (`refresh_token_hash`)',
  'SELECT 1');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
