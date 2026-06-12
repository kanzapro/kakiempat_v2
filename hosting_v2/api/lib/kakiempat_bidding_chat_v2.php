<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';

/**
 * Bidding & Chat System for Kaki Empat Marketplace
 * 
 * Features:
 * - Owner selects bid, opens pre-booking chat
 * - Sitter MUST confirm: "Meluncur Sekarang" OR "Kesepakatan Lain"
 * - Negotiate terms (price, time, services)
 * - Owner can rebroadcast if no agreement
 * - Payment only after agreement
 */

// ============================================================================
// SELECT BID & OPEN CHAT
// ============================================================================

/**
 * Owner selects a bid and opens pre-booking chat room
 * 
 * @param PDO $pdo
 * @param array<string, mixed> $auth
 * @param int $requestId
 * @param int $offerId
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_select_bid(
    PDO $pdo,
    array $auth,
    int $requestId,
    int $offerId
): array {
    v2ApiRequireRole($auth, ['owner', 'founder']);
    
    if ($requestId < 1 || $offerId < 1) {
        v2ApiFail('invalid_params', 'request_id dan offer_id wajib.', 400);
    }
    
    $pdo->beginTransaction();
    try {
        // Verify request exists and belongs to owner
        $stmt = $pdo->prepare(
            'SELECT id, owner_user_id, status, status_extended FROM kakiempa_v2_requests 
             WHERE id = ? FOR UPDATE'
        );
        $stmt->execute([$requestId]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!is_array($request)) {
            v2ApiFail('request_not_found', 'Permintaan tidak ditemukan.', 404);
        }
        if ((int) $request['owner_user_id'] !== $auth['user_id'] && $auth['role'] !== 'founder') {
            v2ApiFail('forbidden', 'Anda tidak memiliki akses ke request ini.', 403);
        }
        if ((string) $request['status'] !== 'open') {
            v2ApiFail('request_not_open', 'Permintaan tidak lagi terbuka untuk bids.', 409);
        }
        
        // Verify offer exists and is pending
        $stmt = $pdo->prepare(
            'SELECT o.*, u.name as sitter_name, u.id as sitter_id 
             FROM kakiempa_v2_offers o
             INNER JOIN kakiempa_v2_users u ON u.id = o.sitter_user_id
             WHERE o.id = ? AND o.request_id = ? AND o.bid_status = "pending" FOR UPDATE'
        );
        $stmt->execute([$offerId, $requestId]);
        $offer = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!is_array($offer)) {
            v2ApiFail('offer_not_found', 'Penawaran tidak ditemukan atau sudah tidak tersedia.', 404);
        }
        
        $sitterId = (int) $offer['sitter_user_id'];
        $bidPrice = (int) ($offer['bid_price'] ?? 0);
        
        // Create bid_chat entry
        $deadlineTime = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        $expiryTime = $deadlineTime->add(new DateInterval('PT24H'));
        
        $stmt = $pdo->prepare(
            'INSERT INTO kakiempa_v2_bid_chats 
             (request_id, offer_id, owner_user_id, sitter_user_id, original_price, 
              sitter_confirmation_status, confirmation_deadline, expires_at, status)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([
            $requestId,
            $offerId,
            $auth['user_id'],
            $sitterId,
            $bidPrice,
            'waiting_confirmation',
            $deadlineTime->format('Y-m-d H:i:s'),
            $expiryTime->format('Y-m-d H:i:s'),
            'active'
        ]);
        
        $bidChatId = (int) $pdo->lastInsertId();
        
        // Update offer status to 'selected'
        $pdo->prepare('UPDATE kakiempa_v2_offers SET bid_status = ? WHERE id = ?')
            ->execute(['selected', $offerId]);
        
        // Update request status_extended
        $pdo->prepare('UPDATE kakiempa_v2_requests SET status_extended = ? WHERE id = ?')
            ->execute(['bid_selected', $requestId]);
        
        // Create system message
        $systemMessage = sprintf(
            'Bid selected by owner. Sitter must confirm within 24 hours.'
        );
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_bid_chat_messages 
             (bid_chat_id, sender_user_id, message_text, message_type)
             VALUES (?, ?, ?, ?)'
        )->execute([
            $bidChatId,
            $auth['user_id'],
            $systemMessage,
            'system_message'
        ]);
        
        // Notify sitter
        kakiempat_event_notifications_push(
            $pdo,
            $sitterId,
            'Penawaran Anda Dipilih!',
            sprintf('Owner memilih penawaran Anda dengan harga Rp %d. Silakan confirm dalam 24 jam.',
                $bidPrice),
            $requestId,
            'bid_selected'
        );
        
        $pdo->commit();
        
        return [
            'bid_chat_id' => (string) $bidChatId,
            'request_id' => (string) $requestId,
            'offer_id' => (string) $offerId,
            'sitter_id' => (string) $sitterId,
            'sitter_name' => (string) ($offer['sitter_name'] ?? ''),
            'bid_price' => $bidPrice,
            'bid_description' => (string) ($offer['bid_description'] ?? ''),
            'confirmation_deadline' => $expiryTime->format('Y-m-d\TH:i:s\Z'),
            'sitter_confirmation_status' => 'waiting_confirmation',
            'status' => 'bid_selected',
            'message' => 'Chat room created. Waiting for sitter confirmation.'
        ];
        
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

// ============================================================================
// SEND CHAT MESSAGE
// ============================================================================

/**
 * Send message in bid chat
 * 
 * @param PDO $pdo
 * @param array<string, mixed> $auth
 * @param int $bidChatId
 * @param string $message
 * @param string $messageType
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_send_message(
    PDO $pdo,
    array $auth,
    int $bidChatId,
    string $message,
    string $messageType = 'text'
): array {
    if ($bidChatId < 1) {
        v2ApiFail('invalid_bid_chat_id', 'bid_chat_id wajib.', 400);
    }
    
    $message = trim($message);
    if ($message === '') {
        v2ApiFail('invalid_message', 'Pesan tidak boleh kosong.', 400);
    }
    
    // Verify user is part of this chat
    $stmt = $pdo->prepare(
        'SELECT id, owner_user_id, sitter_user_id, status, sitter_confirmation_status 
         FROM kakiempa_v2_bid_chats WHERE id = ?'
    );
    $stmt->execute([$bidChatId]);
    $chat = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!is_array($chat)) {
        v2ApiFail('bid_chat_not_found', 'Chat tidak ditemukan.', 404);
    }
    
    $ownerId = (int) $chat['owner_user_id'];
    $sitterId = (int) $chat['sitter_user_id'];
    
    if ($auth['user_id'] !== $ownerId && $auth['user_id'] !== $sitterId) {
        v2ApiFail('forbidden', 'Anda tidak memiliki akses ke chat ini.', 403);
    }
    
    if ((string) $chat['status'] !== 'active') {
        v2ApiFail('chat_not_active', 'Chat sudah ditutup.', 409);
    }
    
    // Insert message
    $stmt = $pdo->prepare(
        'INSERT INTO kakiempa_v2_bid_chat_messages 
         (bid_chat_id, sender_user_id, message_text, message_type)
         VALUES (?, ?, ?, ?)'
    );
    $stmt->execute([
        $bidChatId,
        $auth['user_id'],
        $message,
        $messageType
    ]);
    
    $messageId = (int) $pdo->lastInsertId();
    
    // Notify other party
    $recipientId = $auth['user_id'] === $ownerId ? $sitterId : $ownerId;
    $recipientRole = $auth['user_id'] === $ownerId ? 'sitter' : 'owner';
    
    kakiempat_event_notifications_push(
        $pdo,
        $recipientId,
        'Pesan Baru',
        'Anda memiliki pesan baru di chat pre-booking.',
        null,
        'bid_chat_message'
    );
    
    return [
        'message_id' => (string) $messageId,
        'bid_chat_id' => (string) $bidChatId,
        'created_at' => (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d\TH:i:s\Z'),
        'is_read' => false
    ];
}

// ============================================================================
// SITTER CONFIRM STATUS (MANDATORY)
// ============================================================================

/**
 * Sitter confirm status: "meluncur_sekarang", "kesepakatan_lain", or "tidak_bisa"
 * This is MANDATORY before payment can proceed
 * 
 * @param PDO $pdo
 * @param array<string, mixed> $auth
 * @param int $bidChatId
 * @param string $confirmationStatus
 * @param ?string $message
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_sitter_confirm_status(
    PDO $pdo,
    array $auth,
    int $bidChatId,
    string $confirmationStatus,
    ?string $message = null
): array {
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    
    $validStatuses = ['meluncur_sekarang', 'kesepakatan_lain', 'tidak_bisa'];
    if (!in_array($confirmationStatus, $validStatuses, true)) {
        v2ApiFail('invalid_status', 'Status konfirmasi tidak valid.', 400);
    }
    
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT id, owner_user_id, sitter_user_id, status, sitter_confirmation_status, 
                    request_id, offer_id, original_price 
             FROM kakiempa_v2_bid_chats WHERE id = ? FOR UPDATE'
        );
        $stmt->execute([$bidChatId]);
        $chat = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!is_array($chat)) {
            v2ApiFail('bid_chat_not_found', 'Chat tidak ditemukan.', 404);
        }
        
        $sitterId = (int) $chat['sitter_user_id'];
        if ($auth['user_id'] !== $sitterId && $auth['role'] !== 'founder') {
            v2ApiFail('forbidden', 'Hanya sitter yang dapat confirm status.', 403);
        }
        
        if ((string) $chat['sitter_confirmation_status'] !== 'waiting_confirmation') {
            v2ApiFail('already_confirmed', 'Status sudah di-confirm sebelumnya.', 409);
        }
        
        // Update chat with confirmation
        $pdo->prepare(
            'UPDATE kakiempa_v2_bid_chats 
             SET sitter_confirmation_status = ?, confirmed_at = ? 
             WHERE id = ?'
        )->execute([
            $confirmationStatus,
            (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s'),
            $bidChatId
        ]);
        
        // Add confirmation message to chat
        $confirmationText = match($confirmationStatus) {
            'meluncur_sekarang' => 'Sitter confirm: Meluncur sekarang!',
            'kesepakatan_lain' => 'Sitter: Ada kesepakatan lain yang perlu didiskusikan.',
            'tidak_bisa' => 'Sitter: Tidak bisa melakukan layanan ini.'
        };
        
        $userMessage = $message ? trim($message) : '';
        $fullMessage = $userMessage !== '' ? $userMessage : $confirmationText;
        
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_bid_chat_messages 
             (bid_chat_id, sender_user_id, message_text, message_type)
             VALUES (?, ?, ?, ?)'
        )->execute([
            $bidChatId,
            $sitterId,
            $fullMessage,
            'sitter_confirmation'
        ]);
        
        $ownerId = (int) $chat['owner_user_id'];
        
        // Handle "tidak_bisa" - close chat and notify owner
        if ($confirmationStatus === 'tidak_bisa') {
            $pdo->prepare('UPDATE kakiempa_v2_bid_chats SET status = ? WHERE id = ?')
                ->execute(['cancelled', $bidChatId]);
            
            // Mark offer as rejected
            $pdo->prepare('UPDATE kakiempa_v2_offers SET bid_status = ? WHERE id = ?')
                ->execute(['rejected', (int) $chat['offer_id']]);
            
            $pdo->commit();
            
            kakiempat_event_notifications_push(
                $pdo,
                $ownerId,
                'Penawaran Ditolak',
                'Sitter tidak dapat melakukan layanan ini. Silakan pilih penawaran lain.',
                (int) $chat['request_id'],
                'bid_rejected'
            );
            
            return [
                'bid_chat_id' => (string) $bidChatId,
                'sitter_confirmation_status' => $confirmationStatus,
                'status' => 'cancelled',
                'message' => 'Sitter menolak layanan ini. Chat ditutup.'
            ];
        }
        
        // For "meluncur_sekarang" - ready for payment
        if ($confirmationStatus === 'meluncur_sekarang') {
            $pdo->prepare(
                'UPDATE kakiempa_v2_bid_chats SET terms_agreed_at = ? WHERE id = ?'
            )->execute([
                (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s'),
                $bidChatId
            ]);
            
            $pdo->prepare('UPDATE kakiempa_v2_requests SET status_extended = ? WHERE id = ?')
                ->execute(['terms_agreed', (int) $chat['request_id']]);
            
            $pdo->commit();
            
            kakiempat_event_notifications_push(
                $pdo,
                $ownerId,
                'Sitter Siap!',
                sprintf('Sitter siap melakukan layanan dengan harga Rp %d. Lanjutkan ke pembayaran.',
                    (int) $chat['original_price']),
                (int) $chat['request_id'],
                'sitter_confirmed'
            );
            
            return [
                'bid_chat_id' => (string) $bidChatId,
                'sitter_confirmation_status' => $confirmationStatus,
                'terms_agreed_at' => (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d\TH:i:s\Z'),
                'payment_unlocked' => true,
                'message' => 'Sitter confirm meluncur sekarang. Pembayaran sudah siap.'
            ];
        }
        
        // For "kesepakatan_lain" - keep chat active for negotiation
        $pdo->commit();
        
        kakiempat_event_notifications_push(
            $pdo,
            $ownerId,
            'Kesepakatan Lain',
            'Sitter ingin mendiskusikan kesepakatan lain. Silakan lanjutkan chat.',
            (int) $chat['request_id'],
            'bid_negotiation_needed'
        );
        
        return [
            'bid_chat_id' => (string) $bidChatId,
            'sitter_confirmation_status' => $confirmationStatus,
            'confirmed_at' => (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d\TH:i:s\Z'),
            'payment_unlocked' => false,
            'message' => 'Sitter membuka negosiasi. Lanjutkan chat untuk mengatur kesepakatan.'
        ];
        
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

// ============================================================================
// OWNER AGREE TERMS (after negotiation)
// ============================================================================

/**
 * Owner agree on negotiated terms - UNLOCKS PAYMENT
 * 
 * @param PDO $pdo
 * @param array<string, mixed> $auth
 * @param int $bidChatId
 * @param ?int $negotiatedPrice
 * @param ?string $negotiatedScheduledAt
 * @param ?string $message
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_owner_agree_terms(
    PDO $pdo,
    array $auth,
    int $bidChatId,
    ?int $negotiatedPrice = null,
    ?string $negotiatedScheduledAt = null,
    ?string $message = null
): array {
    v2ApiRequireRole($auth, ['owner', 'founder']);
    
    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT id, owner_user_id, sitter_user_id, sitter_confirmation_status, 
                    original_price, request_id 
             FROM kakiempa_v2_bid_chats WHERE id = ? FOR UPDATE'
        );
        $stmt->execute([$bidChatId]);
        $chat = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!is_array($chat)) {
            v2ApiFail('bid_chat_not_found', 'Chat tidak ditemukan.', 404);
        }
        
        $ownerId = (int) $chat['owner_user_id'];
        if ($auth['user_id'] !== $ownerId && $auth['role'] !== 'founder') {
            v2ApiFail('forbidden', 'Hanya owner yang dapat agree terms.', 403);
        }
        
        if ((string) $chat['sitter_confirmation_status'] !== 'kesepakatan_lain') {
            v2ApiFail('invalid_status', 'Chat harus dalam status kesepakatan_lain untuk agree terms.', 409);
        }
        
        // Update negotiated values
        $finalPrice = $negotiatedPrice ?? (int) $chat['original_price'];
        
        $pdo->prepare(
            'UPDATE kakiempa_v2_bid_chats 
             SET sitter_confirmation_status = "terms_agreed", 
                 negotiated_price = ?, 
                 negotiated_scheduled_at = ?,
                 terms_agreed_at = ? 
             WHERE id = ?'
        )->execute([
            $finalPrice > 0 ? $finalPrice : null,
            $negotiatedScheduledAt,
            (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s'),
            $bidChatId
        ]);
        
        // Update request status
        $pdo->prepare('UPDATE kakiempa_v2_requests SET status_extended = ? WHERE id = ?')
            ->execute(['terms_agreed', (int) $chat['request_id']]);
        
        // Add agreement message
        $agreementText = $message ?? sprintf('Setuju dengan harga Rp %d', $finalPrice);
        
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_bid_chat_messages 
             (bid_chat_id, sender_user_id, message_text, message_type)
             VALUES (?, ?, ?, ?)'
        )->execute([
            $bidChatId,
            $ownerId,
            $agreementText,
            'owner_agreement'
        ]);
        
        $pdo->commit();
        
        // Notify sitter
        kakiempat_event_notifications_push(
            $pdo,
            (int) $chat['sitter_user_id'],
            'Kesepakatan Terbentuk!',
            sprintf('Owner setuju dengan harga Rp %d. Bersiaplah untuk melakukan layanan.',
                $finalPrice),
            (int) $chat['request_id'],
            'terms_agreed'
        );
        
        return [
            'bid_chat_id' => (string) $bidChatId,
            'sitter_confirmation_status' => 'terms_agreed',
            'negotiated_price' => $finalPrice,
            'terms_agreed_at' => (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d\TH:i:s\Z'),
            'payment_unlocked' => true,
            'message' => 'Kesepakatan terbentuk! Pembayaran sudah siap diproses.'
        ];
        
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

// ============================================================================
// GET CHAT MESSAGES & STATUS
// ============================================================================

/**
 * Get all messages in a bid chat with status
 * 
 * @param PDO $pdo
 * @param array<string, mixed> $auth
 * @param int $bidChatId
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_get_messages(
    PDO $pdo,
    array $auth,
    int $bidChatId
): array {
    if ($bidChatId < 1) {
        v2ApiFail('invalid_bid_chat_id', 'bid_chat_id wajib.', 400);
    }
    
    // Verify user can access this chat
    $stmt = $pdo->prepare(
        'SELECT id, owner_user_id, sitter_user_id, status, sitter_confirmation_status,
                original_price, negotiated_price, negotiated_scheduled_at, terms_agreed_at,
                confirmation_deadline, expires_at, request_id 
         FROM kakiempa_v2_bid_chats WHERE id = ?'
    );
    $stmt->execute([$bidChatId]);
    $chat = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!is_array($chat)) {
        v2ApiFail('bid_chat_not_found', 'Chat tidak ditemukan.', 404);
    }
    
    $ownerId = (int) $chat['owner_user_id'];
    $sitterId = (int) $chat['sitter_user_id'];
    
    if ($auth['user_id'] !== $ownerId && $auth['user_id'] !== $sitterId) {
        v2ApiFail('forbidden', 'Anda tidak memiliki akses ke chat ini.', 403);
    }
    
    // Get all messages
    $stmt = $pdo->prepare(
        'SELECT m.id, m.sender_user_id, m.message_text, m.message_type, 
                m.proposal_type, m.proposal_data, m.proposal_status, m.is_read,
                m.created_at, u.name as sender_name 
         FROM kakiempa_v2_bid_chat_messages m
         LEFT JOIN kakiempa_v2_users u ON u.id = m.sender_user_id
         WHERE m.bid_chat_id = ? 
         ORDER BY m.created_at ASC'
    );
    $stmt->execute([$bidChatId]);
    
    $messages = [];
    $unreadCount = 0;
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $senderId = (int) $row['sender_user_id'];
        
        $messageData = [
            'id' => (string) $row['id'],
            'sender_id' => (string) $senderId,
            'sender_name' => (string) ($row['sender_name'] ?? ''),
            'sender_side' => $senderId === $ownerId ? 'owner' : 'sitter',
            'message' => (string) $row['message_text'],
            'message_type' => (string) $row['message_type'],
            'created_at' => (string) $row['created_at'],
            'is_read' => (bool) $row['is_read']
        ];
        
        if ((string) $row['message_type'] === 'negotiation_proposal' && $row['proposal_data']) {
            $messageData['proposal'] = json_decode((string) $row['proposal_data'], true) ?: [];
            $messageData['proposal_status'] = (string) $row['proposal_status'];
        }
        
        $messages[] = $messageData;
        
        if (!(bool) $row['is_read'] && $senderId !== $auth['user_id']) {
            $unreadCount++;
        }
    }
    
    // Mark unread messages as read
    $pdo->prepare(
        'UPDATE kakiempa_v2_bid_chat_messages SET is_read = 1 
         WHERE bid_chat_id = ? AND sender_user_id != ? AND is_read = 0'
    )->execute([$bidChatId, $auth['user_id']]);
    
    $paymentUnlocked = in_array(
        (string) $chat['sitter_confirmation_status'],
        ['meluncur_sekarang', 'terms_agreed'],
        true
    );
    
    return [
        'bid_chat_id' => (string) $bidChatId,
        'request_id' => (string) $chat['request_id'],
        'sitter_confirmation_status' => (string) $chat['sitter_confirmation_status'],
        'original_price' => (int) $chat['original_price'],
        'negotiated_price' => $chat['negotiated_price'] ? (int) $chat['negotiated_price'] : null,
        'negotiated_scheduled_at' => $chat['negotiated_scheduled_at'],
        'confirmation_deadline' => (string) $chat['confirmation_deadline'],
        'confirmed_at' => $chat['confirmed_at'],
        'terms_agreed_at' => $chat['terms_agreed_at'],
        'expires_at' => (string) $chat['expires_at'],
        'payment_unlocked' => $paymentUnlocked,
        'messages' => $messages,
        'unread_count' => $unreadCount
    ];
}

// ============================================================================
// LIST ACTIVE BID CHATS (Owner side)
// ============================================================================

/**
 * Get all active bid chats for owner
 * 
 * @param PDO $pdo
 * @param int $ownerId
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_list_active_chats_owner(
    PDO $pdo,
    int $ownerId
): array {
    $stmt = $pdo->prepare(
        'SELECT bc.id, bc.request_id, bc.offer_id, bc.sitter_user_id, 
                bc.original_price, bc.negotiated_price, bc.sitter_confirmation_status,
                bc.confirmation_deadline, bc.expires_at, bc.terms_agreed_at,
                u.name as sitter_name, u.id as sitter_id,
                (SELECT COUNT(*) FROM kakiempa_v2_bid_chat_messages 
                 WHERE bid_chat_id = bc.id AND sender_user_id != ? AND is_read = 0) as unread_count,
                (SELECT message_text FROM kakiempa_v2_bid_chat_messages 
                 WHERE bid_chat_id = bc.id ORDER BY created_at DESC LIMIT 1) as last_message,
                (SELECT created_at FROM kakiempa_v2_bid_chat_messages 
                 WHERE bid_chat_id = bc.id ORDER BY created_at DESC LIMIT 1) as last_message_time
         FROM kakiempa_v2_bid_chats bc
         INNER JOIN kakiempa_v2_users u ON u.id = bc.sitter_user_id
         WHERE bc.owner_user_id = ? AND bc.status = "active"
         ORDER BY bc.updated_at DESC'
    );
    $stmt->execute([$ownerId, $ownerId]);
    
    $chats = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $chats[] = [
            'bid_chat_id' => (string) $row['id'],
            'request_id' => (string) $row['request_id'],
            'offer_id' => (string) $row['offer_id'],
            'sitter_id' => (string) $row['sitter_user_id'],
            'sitter_name' => (string) $row['sitter_name'],
            'bid_price' => (int) $row['original_price'],
            'negotiated_price' => $row['negotiated_price'] ? (int) $row['negotiated_price'] : null,
            'sitter_confirmation_status' => (string) $row['sitter_confirmation_status'],
            'confirmation_deadline' => (string) $row['confirmation_deadline'],
            'expires_at' => (string) $row['expires_at'],
            'payment_unlocked' => in_array(
                (string) $row['sitter_confirmation_status'],
                ['meluncur_sekarang', 'terms_agreed'],
                true
            ),
            'last_message' => (string) ($row['last_message'] ?? ''),
            'last_message_time' => (string) ($row['last_message_time'] ?? ''),
            'unread_count' => (int) ($row['unread_count'] ?? 0)
        ];
    }
    
    return [
        'bid_chats' => $chats,
        'total' => count($chats)
    ];
}

// ============================================================================
// LIST WAITING CHATS (Sitter side)
// ============================================================================

/**
 * Get all bid chats waiting for sitter confirmation
 * 
 * @param PDO $pdo
 * @param int $sitterId
 * @return array<string, mixed>
 */
function kakiempat_bidding_chat_v2_list_waiting_sitter_chats(
    PDO $pdo,
    int $sitterId
): array {
    $stmt = $pdo->prepare(
        'SELECT bc.id, bc.request_id, bc.offer_id, bc.owner_user_id, 
                bc.original_price, bc.sitter_confirmation_status,
                bc.confirmation_deadline, bc.expires_at,
                u.name as owner_name, u.id as owner_id,
                r.service_code,
                (SELECT COUNT(*) FROM kakiempa_v2_bid_chat_messages 
                 WHERE bid_chat_id = bc.id AND sender_user_id != ? AND is_read = 0) as unread_count,
                (SELECT message_text FROM kakiempa_v2_bid_chat_messages 
                 WHERE bid_chat_id = bc.id ORDER BY created_at DESC LIMIT 1) as last_message
         FROM kakiempa_v2_bid_chats bc
         INNER JOIN kakiempa_v2_users u ON u.id = bc.owner_user_id
         LEFT JOIN kakiempa_v2_requests r ON r.id = bc.request_id
         WHERE bc.sitter_user_id = ? AND bc.sitter_confirmation_status = "waiting_confirmation"
         ORDER BY bc.confirmation_deadline ASC'
    );
    $stmt->execute([$sitterId, $sitterId]);
    
    $chats = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $chats[] = [
            'bid_chat_id' => (string) $row['id'],
            'request_id' => (string) $row['request_id'],
            'owner_id' => (string) $row['owner_user_id'],
            'owner_name' => (string) $row['owner_name'],
            'service_code' => (string) ($row['service_code'] ?? ''),
            'bid_price' => (int) $row['original_price'],
            'confirmation_deadline' => (string) $row['confirmation_deadline'],
            'expires_at' => (string) $row['expires_at'],
            'last_message' => (string) ($row['last_message'] ?? ''),
            'unread_count' => (int) ($row['unread_count'] ?? 0)
        ];
    }
    
    return [
        'bid_chats' => $chats,
        'total' => count($chats)
    ];
}
