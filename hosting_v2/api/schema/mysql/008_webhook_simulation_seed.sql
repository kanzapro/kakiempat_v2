-- Seed simulasi nominal unik 150102 (Forwarder / webhook test)
SET NAMES utf8mb4;

INSERT INTO `kakiempa_v2_users` (`name`, `email`, `password_hash`, `role`, `whatsapp`)
VALUES ('Owner Sim 150102', 'owner.150102@kakiempat.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'owner', '62811150102001')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

SET @owner_id = (SELECT `id` FROM `kakiempa_v2_users` WHERE `email` = 'owner.150102@kakiempat.local' LIMIT 1);

INSERT INTO `kakiempa_v2_users` (`name`, `email`, `password_hash`, `role`, `whatsapp`)
VALUES ('Sitter Sim 150102', 'sitter.150102@kakiempat.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'sitter', '62811150102002')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

SET @sitter_id = (SELECT `id` FROM `kakiempa_v2_users` WHERE `email` = 'sitter.150102@kakiempat.local' LIMIT 1);

INSERT INTO `kakiempa_v2_bookings` (
  `offer_id`, `owner_user_id`, `sitter_user_id`, `status`, `payment_amount`
) VALUES (
  NULL, @owner_id, @sitter_id, 'awaitingPayment', 150102
);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('008_webhook_simulation_seed.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
