-- Pemisahan peran Pet Owner / Pet Sitter (multi-role per akun)

CREATE TABLE IF NOT EXISTS `kakiempa_v2_user_roles` (
  `user_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('owner', 'sitter', 'admin', 'founder') NOT NULL,
  `granted_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`user_id`, `role`),
  KEY `idx_v2_user_roles_role` (`role`),
  CONSTRAINT `fk_v2_user_roles_user` FOREIGN KEY (`user_id`)
    REFERENCES `kakiempa_v2_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Backfill dari kolom role utama
INSERT INTO `kakiempa_v2_user_roles` (`user_id`, `role`)
SELECT `id`, `role` FROM `kakiempa_v2_users`
ON DUPLICATE KEY UPDATE `role` = VALUES(`role`);

-- Backfill dari profil owner/sitter yang sudah ada
INSERT INTO `kakiempa_v2_user_roles` (`user_id`, `role`)
SELECT `user_id`, 'owner' FROM `kakiempa_v2_owner_profiles`
ON DUPLICATE KEY UPDATE `role` = VALUES(`role`);

INSERT INTO `kakiempa_v2_user_roles` (`user_id`, `role`)
SELECT `user_id`, 'sitter' FROM `kakiempa_v2_sitter_profiles`
ON DUPLICATE KEY UPDATE `role` = VALUES(`role`);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('021_user_roles.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
