-- Kaki Empat v2 — profil owner/sitter, hewan, katalog layanan, booking request

SET NAMES utf8mb4;

-- Owner profiles: alamat + koordinat
ALTER TABLE `kakiempa_v2_owner_profiles`
  ADD COLUMN `home_address` TEXT NULL AFTER `whatsapp`,
  ADD COLUMN `latitude` DECIMAL(10, 7) NULL AFTER `home_address`,
  ADD COLUMN `longitude` DECIMAL(10, 7) NULL AFTER `latitude`;

-- Hewan peliharaan: detail tambahan
ALTER TABLE `kakiempa_v2_pets`
  ADD COLUMN `breed` VARCHAR(128) NULL AFTER `species`,
  ADD COLUMN `age_label` VARCHAR(32) NULL AFTER `breed`,
  ADD COLUMN `weight_kg` DECIMAL(8, 2) NULL AFTER `age_label`,
  ADD COLUMN `behavior_notes` TEXT NULL AFTER `weight_kg`;

-- Profil sitter: metadata JSON (bio, layanan, koordinat)
ALTER TABLE `kakiempa_v2_sitter_profiles`
  ADD COLUMN `profile_json` JSON NULL AFTER `status`,
  ADD COLUMN `submitted_at` TIMESTAMP(6) NULL AFTER `profile_json`;

-- Katalog layanan: kategori & urutan
ALTER TABLE `kakiempa_v2_service_catalog`
  ADD COLUMN `category` VARCHAR(64) NOT NULL DEFAULT '' AFTER `title`,
  ADD COLUMN `sort_order` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `category`;

-- Permintaan booking owner
ALTER TABLE `kakiempa_v2_requests`
  ADD COLUMN `service_code` VARCHAR(64) NULL AFTER `status`,
  ADD COLUMN `scheduled_at` DATETIME NULL AFTER `service_code`,
  ADD COLUMN `notes` TEXT NULL AFTER `scheduled_at`,
  ADD COLUMN `pet_ids` JSON NULL AFTER `notes`,
  ADD COLUMN `payment_amount` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Nominal IDR' AFTER `pet_ids`,
  ADD KEY `idx_v2_requests_status` (`status`),
  ADD KEY `idx_v2_requests_service` (`service_code`);

-- Penawaran sitter
ALTER TABLE `kakiempa_v2_offers`
  ADD COLUMN `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) AFTER `status`,
  ADD KEY `idx_v2_offers_sitter` (`sitter_user_id`);

-- Booking: tautan ke request
ALTER TABLE `kakiempa_v2_bookings`
  ADD COLUMN `request_id` BIGINT UNSIGNED NULL AFTER `offer_id`,
  ADD KEY `idx_v2_bookings_request` (`request_id`);

-- Seed 19 layanan kanonis (idempotent)
INSERT INTO `kakiempa_v2_service_catalog` (`code`, `title`, `category`, `sort_order`, `is_active`) VALUES
  ('dog_walking', 'Dog Walking', 'sports', 1, 1),
  ('pet_walking_group', 'Social Walk', 'sports', 2, 1),
  ('pet_swimming', 'Pet Swimming', 'sports', 3, 1),
  ('pet_sitting', 'Pet Sitting', 'boarding', 4, 1),
  ('pet_daycare', 'Pet Daycare', 'boarding', 5, 1),
  ('pet_boarding', 'Pet Boarding', 'boarding', 6, 1),
  ('pet_hotel', 'Pet Hotel', 'boarding', 7, 1),
  ('pet_adoption', 'Pet Adoption', 'boarding', 8, 1),
  ('pet_bike', 'Pet Bike', 'transport', 9, 1),
  ('pet_taxi', 'Pet Taxi', 'transport', 10, 1),
  ('grooming_di_tempat', 'Grooming di Tempat', 'grooming', 11, 1),
  ('pet_spa', 'Pet Spa', 'grooming', 12, 1),
  ('vet_home_visit', 'Vet Home Visit', 'health', 13, 1),
  ('vet_clinic', 'Vet Clinic', 'health', 14, 1),
  ('training_behavioral', 'Training / Behavioral', 'training', 15, 1),
  ('pet_training_advanced', 'Advanced Training', 'training', 16, 1),
  ('pet_photography', 'Pet Photography', 'events', 17, 1),
  ('pet_bereavement', 'Pet Bereavement', 'events', 18, 1),
  ('pet_events', 'Pet Events', 'events', 19, 1)
ON DUPLICATE KEY UPDATE
  `title` = VALUES(`title`),
  `category` = VALUES(`category`),
  `sort_order` = VALUES(`sort_order`),
  `is_active` = VALUES(`is_active`);

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('010_profiles_pets_catalog_booking.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- ---------------------------------------------------------------------------
-- Status request: open → matched → closed | cancelled
-- Status offer:   pending → accepted | rejected
-- Status booking: pending → awaitingPayment → PENDING_VERIFICATION → PAID
-- API endpoints:
--   owner_v2.php   — save_owner_profile, add_pet, get_owner_profile
--   sitter_v2.php  — save_sitter_profile, submit_sitter_verification, get_sitter_profile
--   service_v2.php — get_service_catalog (publik)
--   booking_v2.php — create_request, list_incoming_requests, accept_request,
--                    reject_request, get_booking, list_my_bookings
--   admin_v2.php   — list_pending_sitters, approve_sitter, reject_sitter
-- Sitter harus status approved sebelum accept_request.
-- Owner onboarding: alamat + minimal 1 hewan (onboarding_complete di get_owner_profile).
-- Jalankan setelah 001_core_tables.sql dan sebelum uji end-to-end payment_v2.
-- ---------------------------------------------------------------------------
