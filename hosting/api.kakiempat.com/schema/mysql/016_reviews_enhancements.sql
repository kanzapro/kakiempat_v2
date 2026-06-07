-- Kaki Empat v2 — review metadata + indeks unik per booking — idempotent
SET NAMES utf8mb4;

SET @has_owner_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_reviews'
    AND COLUMN_NAME = 'owner_user_id'
);
SET @sql_owner_col := IF(
  @has_owner_col = 0,
  'ALTER TABLE `kakiempa_v2_reviews`
     ADD COLUMN `owner_user_id` BIGINT UNSIGNED NULL AFTER `booking_id`,
     ADD COLUMN `sitter_user_id` BIGINT UNSIGNED NULL AFTER `owner_user_id`,
     ADD COLUMN `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) AFTER `comment`',
  'SELECT 1'
);
PREPARE stmt_owner_col FROM @sql_owner_col;
EXECUTE stmt_owner_col;
DEALLOCATE PREPARE stmt_owner_col;

SET @has_review_uq := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'kakiempa_v2_reviews'
    AND INDEX_NAME = 'uq_v2_reviews_booking'
);
SET @sql_review_uq := IF(
  @has_review_uq = 0,
  'ALTER TABLE `kakiempa_v2_reviews`
     ADD UNIQUE KEY `uq_v2_reviews_booking` (`booking_id`),
     ADD KEY `idx_v2_reviews_sitter` (`sitter_user_id`)',
  'SELECT 1'
);
PREPARE stmt_review_uq FROM @sql_review_uq;
EXECUTE stmt_review_uq;
DEALLOCATE PREPARE stmt_review_uq;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('016_reviews_enhancements.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
