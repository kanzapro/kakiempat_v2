-- SSO lintas subdomain + reset kata sandi (auth pusat www)

CREATE TABLE IF NOT EXISTS `kakiempa_v2_sso_codes` (
  `code_hash` CHAR(64) NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `target_host` VARCHAR(32) NOT NULL,
  `expires_at` TIMESTAMP(6) NOT NULL,
  `used_at` TIMESTAMP(6) NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`code_hash`),
  KEY `idx_v2_sso_codes_user` (`user_id`),
  KEY `idx_v2_sso_codes_expires` (`expires_at`),
  CONSTRAINT `fk_v2_sso_codes_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_password_resets` (
  `token_hash` CHAR(64) NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `expires_at` TIMESTAMP(6) NOT NULL,
  `used_at` TIMESTAMP(6) NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`token_hash`),
  KEY `idx_v2_password_resets_user` (`user_id`),
  KEY `idx_v2_password_resets_expires` (`expires_at`),
  CONSTRAINT `fk_v2_password_resets_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('020_sso_password_reset.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
