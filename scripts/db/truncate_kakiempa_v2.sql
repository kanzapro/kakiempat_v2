-- Kosongkan semua tabel kakiempa_v2 (struktur tetap).
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE `kakiempa_v2_wallet_ledger`;
TRUNCATE TABLE `kakiempa_v2_notifications`;
TRUNCATE TABLE `kakiempa_v2_messages`;
TRUNCATE TABLE `kakiempa_v2_reviews`;
TRUNCATE TABLE `kakiempa_v2_bookings`;
TRUNCATE TABLE `kakiempa_v2_offers`;
TRUNCATE TABLE `kakiempa_v2_requests`;
TRUNCATE TABLE `kakiempa_v2_service_catalog`;
TRUNCATE TABLE `kakiempa_v2_pets`;
TRUNCATE TABLE `kakiempa_v2_sitter_profiles`;
TRUNCATE TABLE `kakiempa_v2_owner_profiles`;
TRUNCATE TABLE `kakiempa_v2_sessions`;
TRUNCATE TABLE `kakiempa_v2_users`;
TRUNCATE TABLE `kakiempa_v2_schema_migrations`;

SET FOREIGN_KEY_CHECKS = 1;
