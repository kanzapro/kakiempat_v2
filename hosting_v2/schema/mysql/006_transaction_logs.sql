-- Kaki Empat v2 — transaction_logs (Wise / Revolut / Bank Transfer)
-- Produksi MySQL: database kakiempa_v2, tabel kakiempa_v2_transaction_logs
-- sender_bank: SEABANK_WISE | SEABANK_REVOLUT | SEABANK_TRANSFER

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_transaction_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `amount_received` DECIMAL(12, 2) NOT NULL,
  `sender_bank` VARCHAR(50) NOT NULL DEFAULT 'SEABANK_TRANSFER'
    COMMENT 'SEABANK_WISE, SEABANK_REVOLUT, SEABANK_TRANSFER',
  `sender_name` VARCHAR(255) NOT NULL DEFAULT 'Tidak diketahui',
  `raw_notification` TEXT NULL DEFAULT NULL COMMENT 'Teks notifikasi asli (SeaBank forwarder)',
  `raw_timestamp` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Epoch/string dari Android',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_transaction_booking` (`booking_id`),
  KEY `idx_v2_transaction_amount` (`amount_received`),
  KEY `idx_v2_transaction_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
