-- Akun founder master (reset ulang). Password: 123456
INSERT INTO `kakiempa_v2_users` (`name`, `email`, `password_hash`, `role`, `whatsapp`, `is_active`)
VALUES (
  'Founder Kaki Empat',
  '6281248826888@phone.kakiempat.local',
  '$2y$10$snPu8TTOpB4fIsb040HfT.NYCYO0tleOXDY6Pej/3noBQ6cwKuADK',
  'founder',
  '6281248826888',
  1
)
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `password_hash` = VALUES(`password_hash`),
  `role` = VALUES(`role`),
  `is_active` = 1;
