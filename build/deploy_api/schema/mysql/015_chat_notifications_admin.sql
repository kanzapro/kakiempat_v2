-- Kaki Empat v2 — chat (sender), penarikan wallet (admin) — idempotent
SET NAMES utf8mb4;

SET @has_sender := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_messages'
    AND COLUMN_NAME = 'sender_user_id'
);
SET @sql_sender := IF(
  @has_sender = 0,
  'ALTER TABLE `kakiempa_v2_messages` ADD COLUMN `sender_user_id` BIGINT UNSIGNED NULL AFTER `booking_id`',
  'SELECT 1'
);
PREPARE stmt_sender FROM @sql_sender;
EXECUTE stmt_sender;
DEALLOCATE PREPARE stmt_sender;

SET @has_msg_idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_messages'
    AND INDEX_NAME = 'idx_v2_messages_booking_created'
);
SET @sql_msg_idx := IF(
  @has_msg_idx = 0,
  'ALTER TABLE `kakiempa_v2_messages` ADD KEY `idx_v2_messages_booking_created` (`booking_id`, `created_at`)',
  'SELECT 1'
);
PREPARE stmt_msg_idx FROM @sql_msg_idx;
EXECUTE stmt_msg_idx;
DEALLOCATE PREPARE stmt_msg_idx;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_withdrawals` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `amount` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Nominal IDR',
  `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `completed_at` TIMESTAMP(6) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_v2_withdrawals_user` (`user_id`),
  KEY `idx_v2_withdrawals_status` (`status`),
  CONSTRAINT `fk_v2_withdrawals_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('015_chat_notifications_admin.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
