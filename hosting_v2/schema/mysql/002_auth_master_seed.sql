-- Akun master uji (founder). Password: master1 — ganti setelah deploy produksi.
INSERT INTO `kakiempa_v2_users` (`name`, `email`, `password_hash`, `role`, `whatsapp`, `is_active`)
VALUES (
  'Master Founder',
  'founder@kakiempat.internal',
  '$2y$10$bPkuIU8j9YgLI11NI4JoEOoasFFsV/fLR/jEEz.A5Dz4cKirXaypa',
  'founder',
  '6280000000001',
  1
)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);
