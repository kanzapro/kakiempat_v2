-- Kaki Empat v2 — otomatisasi konfirmasi pembayaran (SeaBank webhook)

SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_bookings`
  ADD COLUMN `owner_user_id` BIGINT UNSIGNED NULL AFTER `offer_id`,
  ADD COLUMN `sitter_user_id` BIGINT UNSIGNED NULL AFTER `owner_user_id`,
  ADD COLUMN `payment_amount` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Nominal IDR (bulat)' AFTER `status`,
  ADD COLUMN `payment_verification` VARCHAR(32) NULL DEFAULT NULL AFTER `payment_amount`,
  ADD COLUMN `payment_matched_at` TIMESTAMP(6) NULL DEFAULT NULL AFTER `payment_verification`,
  ADD COLUMN `payment_sender_name` VARCHAR(255) NULL DEFAULT NULL AFTER `payment_matched_at`,
  ADD COLUMN `payment_sender_bank` VARCHAR(64) NULL DEFAULT NULL AFTER `payment_sender_name`,
  ADD KEY `idx_v2_bookings_awaiting_payment` (`status`, `payment_amount`);

CREATE TABLE IF NOT EXISTS `kakiempa_v2_payment_inbound_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nominal` BIGINT UNSIGNED NOT NULL,
  `bank_pengirim` VARCHAR(64) NULL,
  `nama_pengirim` VARCHAR(255) NULL,
  `received_at` TIMESTAMP(6) NOT NULL,
  `matched_booking_id` BIGINT UNSIGNED NULL,
  `raw_payload` JSON NULL,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_payment_inbound_received` (`received_at`),
  KEY `idx_v2_payment_inbound_matched` (`matched_booking_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('004_payment_automation.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- ---------------------------------------------------------------------------
-- Dokumentasi (status booking pembayaran):
--   awaitingPayment — menunggu transfer masuk (nominal harus cocok payment_amount)
--   paid              — webhook cocok, notifikasi owner & sitter terkirim
-- payment_verification: matched | mismatch (satu booking awaiting, nominal salah)
-- Webhook: POST payment_webhook.php — Android NotificationForwarder (SeaBank)
-- Status:  GET payment_status.php?booking_id= — polling Flutter setiap 5 detik
-- ---------------------------------------------------------------------------
