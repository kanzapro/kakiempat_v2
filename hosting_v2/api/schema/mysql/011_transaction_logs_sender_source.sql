-- Kaki Empat v2 — asal dana Wise / Revolut / Bank Transfer + raw_notification
SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_transaction_logs`
  ADD COLUMN `raw_notification` TEXT NULL DEFAULT NULL
    COMMENT 'Teks notifikasi asli (SeaBank forwarder)'
    AFTER `sender_name`;

ALTER TABLE `kakiempa_v2_transaction_logs`
  MODIFY COLUMN `sender_bank` VARCHAR(50) NOT NULL DEFAULT 'SEABANK_TRANSFER'
    COMMENT 'SEABANK_WISE, SEABANK_REVOLUT, SEABANK_TRANSFER';

ALTER TABLE `kakiempa_v2_transaction_logs`
  MODIFY COLUMN `sender_name` VARCHAR(255) NOT NULL DEFAULT 'Tidak diketahui';

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('011_transaction_logs_sender_source.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
