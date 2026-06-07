-- Kaki Empat v2 — review metadata + indeks unik per booking
SET NAMES utf8mb4;

ALTER TABLE `kakiempa_v2_reviews`
  ADD COLUMN `owner_user_id` BIGINT UNSIGNED NULL AFTER `booking_id`,
  ADD COLUMN `sitter_user_id` BIGINT UNSIGNED NULL AFTER `owner_user_id`,
  ADD COLUMN `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) AFTER `comment`;

ALTER TABLE `kakiempa_v2_reviews`
  ADD UNIQUE KEY `uq_v2_reviews_booking` (`booking_id`),
  ADD KEY `idx_v2_reviews_sitter` (`sitter_user_id`);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('016_reviews_enhancements.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- review_v2.php — submit_review, get_sitter_reviews, list_booking_review
