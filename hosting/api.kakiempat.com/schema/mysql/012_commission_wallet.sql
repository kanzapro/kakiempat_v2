-- Kaki Empat v2 — biaya platform otomatis + wallet ledger (Wise/Revolut/QRIS)
SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_requests`
  ADD COLUMN `total_price` BIGINT UNSIGNED NOT NULL DEFAULT 0
    COMMENT 'Tarif layanan (IDR, sebelum fee owner)'
    AFTER `payment_amount`;

ALTER TABLE `kakiempa_v2_bookings`
  ADD COLUMN `total_price` BIGINT UNSIGNED NOT NULL DEFAULT 0
    COMMENT 'Tarif layanan (IDR, sebelum fee owner)'
    AFTER `payment_amount`;

ALTER TABLE `kakiempa_v2_wallet_ledger`
  ADD COLUMN `booking_id` BIGINT UNSIGNED NULL DEFAULT NULL AFTER `user_id`,
  ADD COLUMN `description` VARCHAR(255) NULL DEFAULT NULL AFTER `kind`,
  ADD KEY `idx_v2_wallet_booking` (`booking_id`);

-- amount_cents = nominal IDR (boleh negatif untuk potongan platform_fee)
-- kind: income | platform_fee

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('012_commission_wallet.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
