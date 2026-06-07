-- Kaki Empat v2 — in-app notifications (DB polling, tanpa email/WhatsApp/FCM)
-- Padanan PostgreSQL: in_app_notifications + idx_notif_user_unread

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_in_app_notifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `title` VARCHAR(100) NOT NULL,
  `message` TEXT NOT NULL,
  `booking_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `notification_type` VARCHAR(32) NOT NULL DEFAULT 'general',
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `admin_reviewed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Pelacakan manual admin',
  `admin_notes` VARCHAR(512) NULL DEFAULT NULL COMMENT 'Catatan admin opsional',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_notif_user_unread` (`user_id`, `is_read`),
  KEY `idx_v2_notif_booking` (`booking_id`),
  KEY `idx_v2_notif_created` (`created_at`),
  CONSTRAINT `fk_v2_in_app_notif_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX `idx_v2_bookings_lookup_amount` ON `kakiempa_v2_bookings` (`payment_amount`, `status`);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('009_in_app_notifications.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- ---------------------------------------------------------------------------
-- PostgreSQL v2 → MySQL kakiempa_v2:
--   in_app_notifications     → kakiempa_v2_in_app_notifications
--   idx_notif_user_unread    → idx_v2_notif_user_unread (user_id, is_read)
--   idx_bookings_lookup_amount → idx_v2_bookings_lookup_amount (payment_amount, status)
-- Webhook paid + INSERT notifikasi owner/sitter (polling Flutter ke get_notifications.php).
-- Contoh pesan owner: Payment Confirmed — We have received your payment via Wise for Booking #105.
-- admin_reviewed / admin_notes: kolom pelacakan manual tanpa pihak ketiga.
-- DECIMAL(12,2) nominal: lihat kakiempa_v2_transaction_logs.amount_received.
-- File JSON uploads/notifications/ tetap didukung sebagai fallback ringan.
-- ---------------------------------------------------------------------------
