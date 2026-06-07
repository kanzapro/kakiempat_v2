-- 022: Partner / mini-service registry (super-app fase full)

CREATE TABLE IF NOT EXISTS kakiempa_v2_partner_services (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    category VARCHAR(32) NOT NULL DEFAULT 'general',
    description VARCHAR(512) NULL,
    logo_emoji VARCHAR(8) NOT NULL DEFAULT '🐾',
    action_type VARCHAR(16) NOT NULL DEFAULT 'external_url',
    action_url VARCHAR(512) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    UNIQUE KEY uniq_partner_code (code),
    INDEX idx_partner_active (is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO kakiempa_v2_partner_services
    (code, name, category, description, logo_emoji, action_type, action_url, sort_order)
VALUES
    ('vet_nearby', 'Konsultasi Vet', 'health', 'Temukan klinik hewan terdekat', '🩺', 'external_url', 'https://www.google.com/maps/search/veterinary+clinic+near+me', 10),
    ('pet_food', 'Toko Makanan Hewan', 'commerce', 'Pesan makanan favorit hewan peliharaan', '🛒', 'external_url', 'https://www.tokopedia.com/search?q=makanan+anjing', 20),
    ('pet_grooming_shop', 'Salon Grooming', 'grooming', 'Booking grooming offline di partner', '✂️', 'external_url', 'https://www.google.com/maps/search/pet+grooming', 30)
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`)
VALUES ('022_partner_services.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);
