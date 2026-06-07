-- PostgreSQL v2 — full self-hosted (referensi VPS)
-- PRODUKSI Kaki Empat: MySQL kakiempa_v2 → schema/mysql/009_in_app_notifications.sql

CREATE TYPE user_role AS ENUM ('OWNER', 'SITTER', 'ADMIN');
CREATE TYPE booking_status AS ENUM ('awaitingPayment', 'paid', 'failed', 'cancelled', 'completed');

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

CREATE TABLE transaction_logs (
    id SERIAL PRIMARY KEY,
    booking_id INT REFERENCES bookings(id) ON DELETE SET NULL,
    amount_received NUMERIC(12, 2) NOT NULL,
    sender_bank VARCHAR(50) DEFAULT 'SEABANK_WISE',
    sender_name VARCHAR(100) NOT NULL,
    raw_timestamp VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE in_app_notifications (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    booking_id INT REFERENCES bookings(id) ON DELETE SET NULL,
    notification_type VARCHAR(32) NOT NULL DEFAULT 'general',
    is_read BOOLEAN DEFAULT FALSE,
    admin_reviewed BOOLEAN DEFAULT FALSE,
    admin_notes VARCHAR(512),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bookings_lookup_amount ON bookings (total_amount, status);
CREATE INDEX idx_transaction_amount ON transaction_logs (amount_received);
CREATE INDEX idx_notif_user_unread ON in_app_notifications (user_id, is_read);

-- Webhook (setelah verifikasi token Android):
-- UPDATE bookings SET status = 'paid', updated_at = NOW()
-- WHERE total_amount = 150102.00 AND status = 'awaitingPayment';
-- INSERT INTO in_app_notifications (user_id, title, message, booking_id, notification_type)
-- VALUES (42, 'Payment Confirmed', 'We have received your payment via Wise for Booking #105.', 105, 'payment_paid');
