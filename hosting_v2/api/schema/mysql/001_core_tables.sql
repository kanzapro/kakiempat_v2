-- Kaki Empat v2 — tabel inti (prefix kakiempa_v2_)

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `kakiempa_v2_wallet_ledger`;
DROP TABLE IF EXISTS `kakiempa_v2_notifications`;
DROP TABLE IF EXISTS `kakiempa_v2_messages`;
DROP TABLE IF EXISTS `kakiempa_v2_reviews`;
DROP TABLE IF EXISTS `kakiempa_v2_bookings`;
DROP TABLE IF EXISTS `kakiempa_v2_offers`;
DROP TABLE IF EXISTS `kakiempa_v2_requests`;
DROP TABLE IF EXISTS `kakiempa_v2_service_catalog`;
DROP TABLE IF EXISTS `kakiempa_v2_pets`;
DROP TABLE IF EXISTS `kakiempa_v2_sitter_profiles`;
DROP TABLE IF EXISTS `kakiempa_v2_owner_profiles`;
DROP TABLE IF EXISTS `kakiempa_v2_sessions`;
DROP TABLE IF EXISTS `kakiempa_v2_users`;
DROP TABLE IF EXISTS `kakiempa_v2_schema_migrations`;

CREATE TABLE `kakiempa_v2_schema_migrations` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `filename` VARCHAR(128) NOT NULL,
  `applied_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_v2_migration_file` (`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('owner', 'sitter', 'admin', 'founder') NOT NULL DEFAULT 'owner',
  `whatsapp` VARCHAR(32) NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_v2_users_email` (`email`),
  UNIQUE KEY `uq_v2_users_whatsapp` (`whatsapp`),
  KEY `idx_v2_users_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_sessions` (
  `token_hash` CHAR(64) NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `phone` VARCHAR(32) NOT NULL,
  `role` VARCHAR(32) NOT NULL,
  `expires_at` TIMESTAMP(6) NOT NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`token_hash`),
  KEY `idx_v2_sessions_user` (`user_id`),
  KEY `idx_v2_sessions_expires` (`expires_at`),
  CONSTRAINT `fk_v2_sessions_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_owner_profiles` (
  `user_id` BIGINT UNSIGNED NOT NULL,
  `display_name` VARCHAR(255) NOT NULL,
  `whatsapp` VARCHAR(32) NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_v2_owner_profiles_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_sitter_profiles` (
  `user_id` BIGINT UNSIGNED NOT NULL,
  `display_name` VARCHAR(255) NOT NULL,
  `legal_name` VARCHAR(255) NOT NULL,
  `whatsapp` VARCHAR(32) NULL,
  `address` VARCHAR(512) NOT NULL DEFAULT '-',
  `status` VARCHAR(32) NOT NULL DEFAULT 'draft',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_v2_sitter_profiles_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_pets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_user_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `species` VARCHAR(64) NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_pets_owner` (`owner_user_id`),
  CONSTRAINT `fk_v2_pets_owner` FOREIGN KEY (`owner_user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_service_catalog` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(64) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_v2_catalog_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_user_id` BIGINT UNSIGNED NOT NULL,
  `status` VARCHAR(32) NOT NULL DEFAULT 'draft',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_requests_owner` (`owner_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_offers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `request_id` BIGINT UNSIGNED NOT NULL,
  `sitter_user_id` BIGINT UNSIGNED NOT NULL,
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  PRIMARY KEY (`id`),
  KEY `idx_v2_offers_request` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_bookings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `offer_id` BIGINT UNSIGNED NULL,
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_reviews` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_id` BIGINT UNSIGNED NOT NULL,
  `rating` TINYINT UNSIGNED NOT NULL,
  `comment` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_messages` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_id` BIGINT UNSIGNED NULL,
  `body` TEXT NOT NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_notifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_notifications_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `kakiempa_v2_wallet_ledger` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `amount_cents` BIGINT NOT NULL,
  `kind` VARCHAR(32) NOT NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_wallet_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('001_core_tables.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

SET FOREIGN_KEY_CHECKS = 1;
