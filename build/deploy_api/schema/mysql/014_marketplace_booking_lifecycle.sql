-- Kaki Empat v2 — marketplace (request/offer) + booking lifecycle
SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_requests`
  ADD COLUMN `date_label` VARCHAR(64) NULL AFTER `scheduled_at`,
  ADD COLUMN `time_range` VARCHAR(64) NULL AFTER `date_label`,
  ADD COLUMN `location_json` JSON NULL AFTER `time_range`;

ALTER TABLE `kakiempa_v2_offers`
  ADD COLUMN `price` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Tarif penawaran IDR' AFTER `sitter_user_id`,
  ADD COLUMN `message` TEXT NULL AFTER `price`;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('014_marketplace_booking_lifecycle.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- ---------------------------------------------------------------------------
-- Marketplace (marketplace_v2.php):
--   create_request  — owner: service_type, pets[], date_label, time_range, location, notes, price
--   list_requests   — sitter: pool=open, service_type, radius_km
--   create_offer    — sitter: request_id, price, message
--   accept_offer    — owner: offer_id → booking
--
-- Booking lifecycle (booking_v2.php):
--   sitter_confirm → confirmed
--   sitter_en_route → en_route
--   start_booking → in_progress
--   complete_booking → completed (+ wallet_ledger 8% sitter)
--   cancel_booking → cancelled (owner atau sitter)
-- ---------------------------------------------------------------------------
