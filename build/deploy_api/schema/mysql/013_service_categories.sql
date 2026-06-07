-- Kaki Empat v2 — kategori layanan (tanpa hardcode di PHP)
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_service_categories` (
  `code` VARCHAR(64) NOT NULL,
  `title` VARCHAR(128) NOT NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_service_categories` (`code`, `title`, `sort_order`) VALUES
  ('sports', 'Olahraga', 1),
  ('boarding', 'Penitipan', 2),
  ('transport', 'Transport', 3),
  ('grooming', 'Perawatan', 4),
  ('health', 'Kesehatan', 5),
  ('training', 'Pelatihan', 6),
  ('events', 'Acara & Khusus', 7)
ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `sort_order` = VALUES(`sort_order`);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('013_service_categories.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
