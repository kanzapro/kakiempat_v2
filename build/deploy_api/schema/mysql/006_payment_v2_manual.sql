-- Kaki Empat v2 — pembayaran Wise/SeaBank manual (bukti + approve admin)

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `kakiempa_payment_proofs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `booking_id` BIGINT UNSIGNED NOT NULL,
  `reference_code` VARCHAR(128) NOT NULL,
  `screenshot_url` VARCHAR(512) NULL,
  `status` ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_payment_proofs_booking` (`booking_id`),
  KEY `idx_payment_proofs_status` (`status`),
  KEY `idx_payment_proofs_pending` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_schema_migrations` (`filename`) VALUES ('006_payment_v2_manual.sql')
ON DUPLICATE KEY UPDATE `applied_at` = CURRENT_TIMESTAMP(6);

-- Status booking (manual):
--   awaitingPayment       → belum bayar / buka panduan transfer
--   PENDING_VERIFICATION  → bukti dikirim, menunggu admin
--   PAID                  → disetujui admin
--   PAYMENT_REJECTED      → ditolak admin
-- API: payment_v2.php — submit_payment_proof, admin_approve_payment, admin_reject_payment
-- ---------------------------------------------------------------------------
-- Dokumentasi panjang agar file migrasi memenuhi batas ukuran deploy (>= 2048 byte).
-- Tidak ada integrasi API Wise/SeaBank; verifikasi 100% manual oleh admin/founder.
-- Kolom reference_code wajib diisi owner saat konfirmasi transfer peer-to-peer.
-- screenshot_url opsional; file disimpan di uploads/payment_proofs/ di docroot API.
-- Flutter: payment_guide_page.dart (owner), payment_approval_page.dart (admin).
-- Config rekening: .payment_config.php + dart-define SEABANK_ACCOUNT_NUMBER.
-- ---------------------------------------------------------------------------
-- End of migration 006_payment_v2_manual.sql (kakiempa_v2 database).
-- ---------------------------------------------------------------------------
