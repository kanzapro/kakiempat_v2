-- Kaki Empat v2 — chat (sender), penarikan wallet (admin)
SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_messages`
  ADD COLUMN `sender_user_id` BIGINT UNSIGNED NULL AFTER `booking_id`,
  ADD KEY `idx_v2_messages_booking_created` (`booking_id`, `created_at`);

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

-- ---------------------------------------------------------------------------
-- chat_v2.php         — send_message, get_messages, check_new_messages
-- notification_v2.php — check_new, mark_read, get_notifications
-- admin_v2.php        — list_sitters, list_owners, list_bookings,
--                       approve_sitter, approve_withdrawal (founder only)
-- ---------------------------------------------------------------------------
