-- Kaki Empat v2 — log audit transaksi Forwarder + indeks lookup webhook (MySQL / kakiempa_v2)
-- Padanan skema PostgreSQL: transaction_logs + idx_bookings_lookup + idx_transaction_amount

SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_bookings`
  ADD COLUMN `updated_at` TIMESTAMP(6) NULL DEFAULT NULL
    ON UPDATE CURRENT_TIMESTAMP(6) AFTER `created_at`;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_transaction_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_id` BIGINT UNSIGNED NULL DEFAULT NULL,
  `amount_received` DECIMAL(12, 2) NOT NULL COMMENT 'Nominal unik (contoh 150102.00)',
  `sender_bank` VARCHAR(50) NOT NULL DEFAULT 'SEABANK_WISE',
  `sender_name` VARCHAR(100) NOT NULL DEFAULT 'Tidak diketahui',
  `raw_timestamp` VARCHAR(50) NULL DEFAULT NULL COMMENT 'Epoch/string dari Android',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_transaction_amount` (`amount_received`),
  KEY `idx_v2_transaction_booking` (`booking_id`),
  KEY `idx_v2_transaction_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `kakiempa_v2_payment_inbound_log`
  ADD COLUMN `raw_timestamp` VARCHAR(50) NULL DEFAULT NULL AFTER `received_at`;

CREATE INDEX `idx_v2_bookings_lookup` ON `kakiempa_v2_bookings` (`payment_amount`, `status`);

CREATE INDEX `idx_v2_payment_inbound_nominal` ON `kakiempa_v2_payment_inbound_log` (`nominal`);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('007_transaction_logs_optimization.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- ---------------------------------------------------------------------------
-- Pemetaan PostgreSQL → MySQL (kakiempa_v2):
--   users              → kakiempa_v2_users
--   pets               → kakiempa_v2_pets
--   bookings           → kakiempa_v2_bookings (payment_amount = total_amount unik)
--   transaction_logs   → kakiempa_v2_transaction_logs (+ kakiempa_v2_payment_inbound_log)
--   idx_bookings_lookup → idx_v2_bookings_lookup (payment_amount, status)
-- Webhook: WHERE status='awaitingPayment' AND payment_amount=? → UPDATE status='paid'
-- Gunakan DECIMAL(12,2) bukan FLOAT agar pencocokan nominal persis (150102.00).
-- RAM 4GB: indeks komposit menghindari full table scan saat forwarder kirim nominal.
-- ---------------------------------------------------------------------------
-- Contoh simulasi: booking payment_amount=150102, status=awaitingPayment
-- Forwarder POST nominal 150102 → payment_webhook.php → paid + baris transaction_logs.
-- ---------------------------------------------------------------------------
