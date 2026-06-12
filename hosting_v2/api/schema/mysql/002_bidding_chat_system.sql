-- ============================================================================
-- Kaki Empat V2: Bidding & Chat System Migration
-- ============================================================================
-- This migration adds support for multi-sitter bidding, negotiation chat,
-- and mandatory sitter confirmation before payment.
--
-- Features:
-- - Owner creates request, broadcast to multiple sitters
-- - Sitters submit bids with price & description
-- - Owner selects sitter, opens pre-booking chat
-- - Sitter MUST confirm: "Meluncur Sekarang" OR "Kesepakatan Lain"
-- - Negotiate terms if needed
-- - Owner can rebroadcast if no agreement
-- - Payment only after agreement
-- ============================================================================

-- 1. Extend kakiempa_v2_requests table
-- ============================================================================
ALTER TABLE kakiempa_v2_requests ADD COLUMN (
    sitter_pool_ids JSON DEFAULT NULL COMMENT 'List of sitter user_ids eligible for this service',
    max_price INT DEFAULT 0 COMMENT 'Owner budget in rupiah',
    rebroadcast_count INT DEFAULT 0 COMMENT 'How many times rebroadcasted',
    last_broadcast_at DATETIME DEFAULT NULL COMMENT 'Timestamp of last broadcast',
    status_extended ENUM(
        'open',                 -- Initial: open for bids
        'bid_selected',         -- Owner selected one bid, chat opened
        'terms_agreed',         -- Sitter confirmed + negotiation finished
        'payment_pending',      -- Waiting for owner payment
        'paid',                 -- Payment confirmed
        'rebroadcast',          -- Owner clicked "Broadcast Ulang"
        'closed',               -- Booking completed/cancelled
        'expired'               -- No response > 48h
    ) DEFAULT 'open' COMMENT 'Extended status for bidding workflow'
);

-- Add indexes for new columns
ALTER TABLE kakiempa_v2_requests ADD INDEX idx_status_extended (status_extended);
ALTER TABLE kakiempa_v2_requests ADD INDEX idx_last_broadcast_at (last_broadcast_at);

-- 2. Create kakiempa_v2_bid_chats table (Pre-booking negotiation chat)
-- ============================================================================
CREATE TABLE IF NOT EXISTS kakiempa_v2_bid_chats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    offer_id INT NOT NULL,
    owner_user_id INT NOT NULL,
    sitter_user_id INT NOT NULL,
    
    -- Sitter Confirmation Status (MANDATORY)
    sitter_confirmation_status ENUM(
        'waiting_confirmation',  -- Waiting for sitter to confirm
        'meluncur_sekarang',     -- Sitter: start immediately
        'kesepakatan_lain',      -- Sitter: open for negotiation
        'tidak_bisa',            -- Sitter: cannot do it
        'terms_agreed',          -- Both: agreement reached, ready for payment
        'expired',               -- 24h timeout without response
        'cancelled'              -- Owner cancelled, broadcast retry
    ) DEFAULT 'waiting_confirmation' COMMENT 'Sitter confirmation status',
    
    -- Pricing
    original_price INT NOT NULL COMMENT 'Original bid price',
    negotiated_price INT DEFAULT NULL COMMENT 'New price if negotiated',
    
    -- Scheduling
    negotiated_scheduled_at DATETIME DEFAULT NULL COMMENT 'New scheduled time if changed',
    
    -- Negotiation documentation
    negotiation_notes JSON DEFAULT NULL COMMENT 'Array of negotiation history',
    
    -- Deadlines & Confirmations
    confirmation_deadline DATETIME NOT NULL COMMENT '24h deadline for sitter confirmation',
    confirmed_at DATETIME DEFAULT NULL COMMENT 'When sitter confirmed status',
    terms_agreed_at DATETIME DEFAULT NULL COMMENT 'When agreement was reached',
    expires_at DATETIME NOT NULL COMMENT '24h from creation, auto-expire if no confirmation',
    
    -- Chat status
    status ENUM(
        'active',               -- Chat is ongoing
        'expired',              -- 24h timeout
        'converted_to_booking', -- Chat converted to booking
        'cancelled'             -- Cancelled by owner (rebroadcast)
    ) DEFAULT 'active' COMMENT 'Chat status',
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (request_id) REFERENCES kakiempa_v2_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (offer_id) REFERENCES kakiempa_v2_offers(id) ON DELETE CASCADE,
    FOREIGN KEY (owner_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE,
    FOREIGN KEY (sitter_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE,
    
    INDEX idx_request_id (request_id),
    INDEX idx_offer_id (offer_id),
    INDEX idx_owner_user_id (owner_user_id),
    INDEX idx_sitter_user_id (sitter_user_id),
    INDEX idx_sitter_confirmation_status (sitter_confirmation_status),
    INDEX idx_confirmation_deadline (confirmation_deadline),
    INDEX idx_expires_at (expires_at),
    INDEX idx_status (status),
    INDEX idx_terms_agreed_at (terms_agreed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Create kakiempa_v2_bid_chat_messages table
-- ============================================================================
CREATE TABLE IF NOT EXISTS kakiempa_v2_bid_chat_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    bid_chat_id INT NOT NULL,
    sender_user_id INT NOT NULL,
    message_text TEXT NOT NULL,
    
    -- Message Type
    message_type ENUM(
        'text',                 -- Regular chat message
        'sitter_confirmation',  -- Sitter status: meluncur/kesepakatan/tidak_bisa
        'negotiation_proposal', -- Propose price/time/service change
        'owner_agreement',      -- Owner agree on terms
        'system_message'        -- System notification
    ) DEFAULT 'text' COMMENT 'Type of message',
    
    -- Negotiation fields (for negotiation_proposal type)
    proposal_type VARCHAR(50) DEFAULT NULL COMMENT 'price_change, time_change, additional_service',
    proposal_data JSON DEFAULT NULL COMMENT '{"old_value": ..., "new_value": ..., "reason": ...}',
    proposal_status ENUM('pending','agreed','rejected') DEFAULT 'pending' COMMENT 'Negotiation proposal status',
    
    is_read TINYINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (bid_chat_id) REFERENCES kakiempa_v2_bid_chats(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_user_id) REFERENCES kakiempa_v2_users(id) ON DELETE CASCADE,
    
    INDEX idx_bid_chat_id (bid_chat_id),
    INDEX idx_sender_user_id (sender_user_id),
    INDEX idx_message_type (message_type),
    INDEX idx_created_at (created_at),
    INDEX idx_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Extend kakiempa_v2_offers table
-- ============================================================================
ALTER TABLE kakiempa_v2_offers ADD COLUMN (
    bid_price INT DEFAULT 0 COMMENT 'Sitter quoted price for this offer',
    bid_description VARCHAR(500) DEFAULT NULL COMMENT 'Offer description: "bisa pickup", "free consultation", etc',
    bid_status ENUM(
        'pending',       -- Waiting for owner selection
        'selected',      -- Owner selected this bid
        'agreed',        -- Terms agreed after chat
        'rejected',      -- Owner rejected / broadcast retry
        'cancelled',     -- Sitter withdrew
        'expired'        -- Bid expired (24h)
    ) DEFAULT 'pending' COMMENT 'Bid status',
    sitter_rating DECIMAL(3,2) DEFAULT NULL COMMENT 'Sitter rating at time of bid',
    bid_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'When bid was submitted'
);

-- Add indexes for offer fields
ALTER TABLE kakiempa_v2_offers ADD INDEX idx_bid_status (bid_status);
ALTER TABLE kakiempa_v2_offers ADD INDEX idx_bid_created_at (bid_created_at);

-- 5. Create kakiempa_v2_broadcast_events table
-- ============================================================================
CREATE TABLE IF NOT EXISTS kakiempa_v2_broadcast_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT DEFAULT NULL,
    offer_id INT DEFAULT NULL,
    
    event_type ENUM(
        'request_posted',          -- New request broadcast to sitters
        'bid_received',            -- Sitter submitted a bid
        'bid_selected',            -- Owner selected a bid, chat opened
        'sitter_confirmed',        -- Sitter confirmed status (meluncur/kesepakatan/tidak_bisa)
        'negotiation_proposed',    -- Negotiation proposal sent
        'terms_agreed',            -- Agreement reached
        'rebroadcast_initiated',   -- Owner clicked "Broadcast Ulang"
        'chat_expired',            -- 24h timeout
        'booking_created'          -- Booking formed after payment
    ) NOT NULL COMMENT 'Type of broadcast event',
    
    recipient_user_ids JSON DEFAULT NULL COMMENT 'Array of recipient user IDs',
    recipient_role VARCHAR(50) DEFAULT NULL COMMENT 'owner, sitter, both, admin',
    
    event_data JSON DEFAULT NULL COMMENT 'Event-specific data payload',
    broadcast_sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (request_id) REFERENCES kakiempa_v2_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (offer_id) REFERENCES kakiempa_v2_offers(id) ON DELETE CASCADE,
    
    INDEX idx_event_type (event_type),
    INDEX idx_broadcast_sent_at (broadcast_sent_at),
    INDEX idx_request_id (request_id),
    INDEX idx_offer_id (offer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Create kakiempa_v2_broadcast_history table (Audit log)
-- ============================================================================
CREATE TABLE IF NOT EXISTS kakiempa_v2_broadcast_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    
    action VARCHAR(100) NOT NULL COMMENT 'initial_broadcast, rebroadcast',
    rebroadcast_count INT DEFAULT 0,
    trigger_reason VARCHAR(255) DEFAULT NULL COMMENT 'owner_clicked, chat_expired, sitter_rejected, no_agreement',
    
    old_sitter_pool JSON DEFAULT NULL,
    new_sitter_pool JSON DEFAULT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (request_id) REFERENCES kakiempa_v2_requests(id) ON DELETE CASCADE,
    
    INDEX idx_request_id (request_id),
    INDEX idx_action (action),
    INDEX idx_rebroadcast_count (rebroadcast_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
