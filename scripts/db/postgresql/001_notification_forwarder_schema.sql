-- Referensi PostgreSQL (opsional / dokumentasi).
-- PRODUKSI Kaki Empat v2 memakai MySQL: database kakiempa_v2
-- Jalankan padanan MySQL: hosting/api.kakiempat.com/schema/mysql/007_transaction_logs_optimization.sql

-- 1. ENUM TYPE
CREATE TYPE user_role AS ENUM ('OWNER', 'SITTER', 'ADMIN');
CREATE TYPE booking_status AS ENUM ('awaitingPayment', 'paid', 'failed', 'cancelled', 'completed');

-- 2. USERS
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'OWNER',
    phone_number VARCHAR(20),
    nationality VARCHAR(50) DEFAULT 'International',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. PETS
CREATE TABLE pets (
    id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES users(id) ON DELETE CASCADE,
    pet_name VARCHAR(50) NOT NULL,
    pet_type VARCHAR(30) NOT NULL,
    breed VARCHAR(50),
    age_months INT,
    special_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. BOOKINGS
CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES users(id),
    sitter_id INT REFERENCES users(id),
    pet_id INT REFERENCES pets(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    status booking_status NOT NULL DEFAULT 'awaitingPayment',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. TRANSACTION LOGS (audit SeaBank / Wise forwarder)
CREATE TABLE transaction_logs (
    id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(id) ON DELETE SET NULL,
    amount_received NUMERIC(12, 2) NOT NULL,
    sender_bank VARCHAR(50) DEFAULT 'SEABANK_TRANSFER',
    sender_name VARCHAR(255) NOT NULL,
    raw_notification TEXT,
    raw_timestamp VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. INDEXES (webhook lookup instan)
CREATE INDEX idx_bookings_lookup ON bookings (total_amount, status);
CREATE INDEX idx_transaction_amount ON transaction_logs (amount_received);

-- Query otomatis payment_webhook.php (setelah token hash_equals lolos):
-- UPDATE bookings SET status = 'paid', updated_at = NOW()
-- WHERE total_amount = 150102.00 AND status = 'awaitingPayment';
