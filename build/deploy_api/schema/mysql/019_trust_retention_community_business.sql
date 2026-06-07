-- 019: Trust docs, loyalty, referral, pet gallery, promotions, achievements

CREATE TABLE IF NOT EXISTS kakiempa_v2_loyalty_points (
    user_id INT UNSIGNED NOT NULL PRIMARY KEY,
    points INT NOT NULL DEFAULT 0,
    updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_loyalty_user FOREIGN KEY (user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_loyalty_transactions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    points INT NOT NULL,
    kind VARCHAR(32) NOT NULL,
    booking_id INT UNSIGNED NULL,
    description VARCHAR(255) NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_loyalty_tx_user (user_id),
    CONSTRAINT fk_loyalty_tx_user FOREIGN KEY (user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_referral_codes (
    user_id INT UNSIGNED NOT NULL PRIMARY KEY,
    code VARCHAR(12) NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uniq_referral_code (code),
    CONSTRAINT fk_referral_user FOREIGN KEY (user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_referral_redemptions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    referrer_user_id INT UNSIGNED NOT NULL,
    referee_user_id INT UNSIGNED NOT NULL,
    bonus_referrer INT NOT NULL DEFAULT 20000,
    discount_referee_pct INT NOT NULL DEFAULT 10,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uniq_referee (referee_user_id),
    INDEX idx_referrer (referrer_user_id),
    CONSTRAINT fk_ref_referrer FOREIGN KEY (referrer_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE,
    CONSTRAINT fk_ref_referee FOREIGN KEY (referee_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_pet_gallery (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    owner_user_id INT UNSIGNED NOT NULL,
    pet_id INT UNSIGNED NULL,
    caption VARCHAR(512) NULL,
    image_data MEDIUMTEXT NOT NULL,
    likes_count INT NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_gallery_owner (owner_user_id),
    CONSTRAINT fk_gallery_owner FOREIGN KEY (owner_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_pet_gallery_likes (
    gallery_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    PRIMARY KEY (gallery_id, user_id),
    CONSTRAINT fk_gallery_like_item FOREIGN KEY (gallery_id) REFERENCES kakiempa_v2_pet_gallery(id) ON DELETE CASCADE,
    CONSTRAINT fk_gallery_like_user FOREIGN KEY (user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_sitter_promotions (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sitter_user_id INT UNSIGNED NOT NULL,
    code VARCHAR(16) NOT NULL,
    discount_percent INT NOT NULL DEFAULT 10,
    max_uses INT NOT NULL DEFAULT 1,
    used_count INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uniq_promo_code (code),
    INDEX idx_promo_sitter (sitter_user_id),
    CONSTRAINT fk_promo_sitter FOREIGN KEY (sitter_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS kakiempa_v2_sitter_achievements (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    sitter_user_id INT UNSIGNED NOT NULL,
    badge_code VARCHAR(32) NOT NULL,
    earned_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uniq_sitter_badge (sitter_user_id, badge_code),
    CONSTRAINT fk_achievement_sitter FOREIGN KEY (sitter_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
