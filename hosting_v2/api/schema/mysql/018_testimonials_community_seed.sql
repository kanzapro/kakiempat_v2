-- Kaki Empat v2 — testimoni & posting komunitas (seed development)

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_testimonials` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role` ENUM('sitter', 'owner') NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `city` VARCHAR(128) NOT NULL DEFAULT '',
  `service_role` VARCHAR(128) NOT NULL DEFAULT '',
  `text` TEXT NOT NULL,
  `rating` DECIMAL(2,1) NOT NULL DEFAULT 5.0,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_testimonials_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kakiempa_v2_community_posts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `author_name` VARCHAR(128) NOT NULL,
  `caption` TEXT NOT NULL,
  `likes_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `comments_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_v2_community_posts_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `kakiempa_v2_testimonials` (`role`, `name`, `city`, `service_role`, `text`, `rating`, `created_at`) VALUES
('sitter', 'Putri', 'Denpasar', 'Dog Walker',
 'Awalnya cuma coba-coba, sekarang tiap minggu pasti ada aja yang booking. Paling seneng bisa sambil olahraga, bonusnya dapet duit!', 5.0, NOW(6) - INTERVAL 14 DAY),
('sitter', 'Rian', 'Surabaya', 'Grooming',
 'Alat grooming udah numpuk di rumah, eh ternyata banyak yang butuh jasa grooming panggilan. Sekarang aku bisa buka layanan dari rumah.', 4.9, NOW(6) - INTERVAL 10 DAY),
('sitter', 'Dewi', 'Jakarta', 'Vet',
 'Jadi lebih fleksibel. Owner senang karena hewannya nggak perlu stres ke klinik.', 5.0, NOW(6) - INTERVAL 7 DAY),
('owner', 'Maya', 'Jakarta', 'Pemilik Milo',
 'Milo anjingnya hiperaktif, susah banget ditinggal kerja. Sejak pakai Kaki Empat, tiap siang ada yang ngajak jalan. Sekarang Milo udah nggak ngerusak sofa lagi!', 5.0, NOW(6) - INTERVAL 5 DAY),
('owner', 'Alex', 'Bali', 'Bule di Bali',
 'I was worried leaving my dog at a pet hotel. But the sitter sent me photos every hour. I could enjoy my vacation without feeling guilty.', 5.0, NOW(6) - INTERVAL 3 DAY),
('owner', 'Sari', 'Jakarta', 'Jakarta',
 'Kucingku perlu grooming rutin tapi males ke salon. Ada sitter yang datang ke rumah, selesai dalam 1 jam. Kucingku happy, aku happy!', 4.8, NOW(6) - INTERVAL 1 DAY);

INSERT INTO `kakiempa_v2_community_posts` (`author_name`, `caption`, `likes_count`, `comments_count`, `created_at`) VALUES
('Putri · Dog Walker', 'Jalan pagi bareng Milo 🐕. Dia seneng banget ketemu temen baru di taman.', 24, 5, NOW(6) - INTERVAL 2 HOUR),
('Rian · Grooming', 'Hasil grooming hari ini! Coco sekarang kinclong ✨✂️', 41, 8, NOW(6) - INTERVAL 5 HOUR),
('Dewi · Vet', 'Kunjungan ke rumah Bu Sari. Kucingnya manis banget, langsung nurut pas dikasih vitamin.', 18, 3, NOW(6) - INTERVAL 1 DAY),
('Andi · Pet Taxi', 'First time pet taxi! Jemput Max dari vet, dia tenang banget di perjalanan 🚗', 32, 6, NOW(6) - INTERVAL 2 DAY);
