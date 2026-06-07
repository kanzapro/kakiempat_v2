-- Seed uji: satu booking awaitingPayment Rp 250.000 (jalankan setelah 004).
SET NAMES utf8mb4;

INSERT INTO `kakiempa_v2_users` (`name`, `email`, `password_hash`, `role`)
VALUES ('Owner Test Pay', 'owner.pay.test@kakiempat.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'owner')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

SET @owner_id = (SELECT `id` FROM `kakiempa_v2_users` WHERE `email` = 'owner.pay.test@kakiempat.local' LIMIT 1);

INSERT INTO `kakiempa_v2_users` (`name`, `email`, `password_hash`, `role`)
VALUES ('Sitter Test Pay', 'sitter.pay.test@kakiempat.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'sitter')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

SET @sitter_id = (SELECT `id` FROM `kakiempa_v2_users` WHERE `email` = 'sitter.pay.test@kakiempat.local' LIMIT 1);

INSERT INTO `kakiempa_v2_bookings` (
  `offer_id`, `owner_user_id`, `sitter_user_id`, `status`, `payment_amount`
) VALUES (
  NULL, @owner_id, @sitter_id, 'awaitingPayment', 250000
);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('005_payment_test_seed.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
