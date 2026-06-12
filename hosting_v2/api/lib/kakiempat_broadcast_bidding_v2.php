<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/**
 * Broadcast Events for Bidding System
 * 
 * Tracks and broadcasts bidding events in real-time:
 * - Request posted
 * - Bid received
 * - Bid selected
 * - Sitter confirmed
 * - Terms agreed
 * - Rebroadcast initiated
 * - Chat expired
 */

// ============================================================================
// LOG BROADCAST EVENT
// ============================================================================

/**
 * Record a broadcast event
 * 
 * @param PDO $pdo
 * @param ?int $requestId
 * @param ?int $offerId
 * @param string $eventType
 * @param array<int|string> $recipientUserIds
 * @param string $recipientRole
 * @param array<string, mixed> $eventData
 * @return int Event ID
 */
function kakiempat_broadcast_bidding_v2_log_event(
    PDO $pdo,
    ?int $requestId,
    ?int $offerId,
    string $eventType,
    array $recipientUserIds,
    string $recipientRole,
    array $eventData
): int {
    $validTypes = [
        'request_posted', 'bid_received', 'bid_selected', 'sitter_confirmed',
        'negotiation_proposed', 'terms_agreed', 'rebroadcast_initiated',
        'chat_expired', 'booking_created'
    ];
    
    if (!in_array($eventType, $validTypes, true)) {
        throw new InvalidArgumentException("Invalid event_type: $eventType");
    }
    
    $stmt = $pdo->prepare(
        'INSERT INTO kakiempa_v2_broadcast_events 
         (request_id, offer_id, event_type, recipient_user_ids, recipient_role, event_data)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    
    $stmt->execute([
        $requestId,
        $offerId,
        $eventType,
        json_encode($recipientUserIds, JSON_UNESCAPED_UNICODE),
        $recipientRole,
        json_encode($eventData, JSON_UNESCAPED_UNICODE)
    ]);
    
    return (int) $pdo->lastInsertId();
}

// ============================================================================
// POLL BROADCAST EVENTS (for real-time updates)
// ============================================================================

/**
 * Get broadcast events for a user (since last poll)
 * 
 * @param PDO $pdo
 * @param int $userId
 * @param ?int $lastPollTimestamp
 * @return array<string, mixed>
 */
function kakiempat_broadcast_bidding_v2_poll_events(
    PDO $pdo,
    int $userId,
    ?int $lastPollTimestamp = null
): array {
    $condition = '';
    $params = ["%\"$userId\"%"];
    
    if ($lastPollTimestamp !== null) {
        $condition = ' AND UNIX_TIMESTAMP(broadcast_sent_at) > ?';
        $params[] = $lastPollTimestamp;
    } else {
        // Default: last 24 hours
        $condition = ' AND broadcast_sent_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)';
    }
    
    $query = "SELECT id, request_id, offer_id, event_type, recipient_user_ids, 
                     recipient_role, event_data, broadcast_sent_at
              FROM kakiempa_v2_broadcast_events 
              WHERE JSON_CONTAINS(recipient_user_ids, ?) $condition
              ORDER BY broadcast_sent_at DESC
              LIMIT 50";
    
    $stmt = $pdo->prepare($query);
    $stmt->execute($params);
    
    $events = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $events[] = [
            'event_id' => (string) $row['id'],
            'request_id' => $row['request_id'] ? (string) $row['request_id'] : null,
            'offer_id' => $row['offer_id'] ? (string) $row['offer_id'] : null,
            'event_type' => (string) $row['event_type'],
            'recipient_role' => (string) $row['recipient_role'],
            'event_data' => json_decode((string) $row['event_data'], true) ?: [],
            'timestamp' => (string) $row['broadcast_sent_at']
        ];
    }
    
    return [
        'events' => $events,
        'count' => count($events),
        'timestamp_polled' => date('Y-m-d H:i:s')
    ];
}

// ============================================================================
// REBROADCAST REQUEST (Owner broadcast ulang)
// ============================================================================

/**
 * Owner rebroadcast request to get new bids
 * 
 * @param PDO $pdo
 * @param int $requestId
 * @param int $bidChatId
 * @param string $reason
 * @return array<string, mixed>
 */
function kakiempat_broadcast_bidding_v2_rebroadcast_request(
    PDO $pdo,
    int $requestId,
    int $bidChatId,
    string $reason
): array {
    $validReasons = ['no_response', 'sitter_rejected', 'no_agreement', 'chat_expired'];
    if (!in_array($reason, $validReasons, true)) {
        throw new InvalidArgumentException("Invalid reason: $reason");
    }
    
    $pdo->beginTransaction();
    try {
        // Get current request
        $stmt = $pdo->prepare(
            'SELECT id, owner_user_id, sitter_pool_ids, rebroadcast_count 
             FROM kakiempa_v2_requests WHERE id = ? FOR UPDATE'
        );
        $stmt->execute([$requestId]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!is_array($request)) {
            throw new RuntimeException('Request not found');
        }
        
        // Close current bid_chat
        $pdo->prepare('UPDATE kakiempa_v2_bid_chats SET status = ? WHERE id = ?')
            ->execute(['cancelled', $bidChatId]);
        
        // Get current offer and mark as rejected
        $stmt = $pdo->prepare(
            'SELECT offer_id FROM kakiempa_v2_bid_chats WHERE id = ?'
        );
        $stmt->execute([$bidChatId]);
        $offerId = $stmt->fetchColumn();
        
        if ($offerId) {
            $pdo->prepare('UPDATE kakiempa_v2_offers SET bid_status = ? WHERE id = ?')
                ->execute(['rejected', $offerId]);
        }
        
        // Increment rebroadcast count
        $newCount = ((int) $request['rebroadcast_count']) + 1;
        
        // Update request status
        $pdo->prepare(
            'UPDATE kakiempa_v2_requests 
             SET status_extended = ?, rebroadcast_count = ?, last_broadcast_at = ? 
             WHERE id = ?'
        )->execute([
            'rebroadcast',
            $newCount,
            (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s'),
            $requestId
        ]);
        
        // Record in broadcast_history
        $oldPool = $request['sitter_pool_ids'] ? 
            json_decode((string) $request['sitter_pool_ids'], true) : null;
        
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_broadcast_history 
             (request_id, action, rebroadcast_count, trigger_reason, old_sitter_pool)
             VALUES (?, ?, ?, ?, ?)'
        )->execute([
            $requestId,
            'rebroadcast',
            $newCount,
            $reason,
            $oldPool ? json_encode($oldPool, JSON_UNESCAPED_UNICODE) : null
        ]);
        
        // Log broadcast event
        kakiempat_broadcast_bidding_v2_log_event(
            $pdo,
            $requestId,
            null,
            'rebroadcast_initiated',
            [],
            'all',
            [
                'reason' => $reason,
                'rebroadcast_count' => $newCount,
                'message' => "Request rebroadcasted ($reason). Waiting for new bids."
            ]
        );
        
        $pdo->commit();
        
        return [
            'request_id' => (string) $requestId,
            'rebroadcast_count' => $newCount,
            'status' => 'rebroadcast',
            'reason' => $reason,
            'message' => 'Permintaan di-broadcast ulang. Menunggu penawaran baru dari sitter.'
        ];
        
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

// ============================================================================
// AUTO-EXPIRE CHATS (cron job)
// ============================================================================

/**
 * Auto-expire bid chats that exceeded 24h deadline
 * Run this via cron job every hour
 * 
 * @param PDO $pdo
 * @return int Count of expired chats
 */
function kakiempat_broadcast_bidding_v2_expire_old_chats(PDO $pdo): int {
    $now = (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s');
    
    $pdo->beginTransaction();
    try {
        // Get chats to expire
        $stmt = $pdo->prepare(
            'SELECT id, request_id, owner_user_id, sitter_user_id, offer_id 
             FROM kakiempa_v2_bid_chats 
             WHERE status = "active" AND expires_at < ? AND sitter_confirmation_status = "waiting_confirmation"'
        );
        $stmt->execute([$now]);
        $expiredChats = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
        
        if ($expiredChats === []) {
            $pdo->commit();
            return 0;
        }
        
        foreach ($expiredChats as $chat) {
            $chatId = (int) $chat['id'];
            $requestId = (int) $chat['request_id'];
            $ownerId = (int) $chat['owner_user_id'];
            $offerId = (int) ($chat['offer_id'] ?? 0);
            
            // Update chat status
            $pdo->prepare('UPDATE kakiempa_v2_bid_chats SET status = ?, sitter_confirmation_status = ? WHERE id = ?')
                ->execute(['expired', 'expired', $chatId]);
            
            // Mark offer as expired
            if ($offerId > 0) {
                $pdo->prepare('UPDATE kakiempa_v2_offers SET bid_status = ? WHERE id = ?')
                    ->execute(['expired', $offerId]);
            }
            
            // Log event
            kakiempat_broadcast_bidding_v2_log_event(
                $pdo,
                $requestId,
                $offerId > 0 ? $offerId : null,
                'chat_expired',
                [$ownerId],
                'owner',
                ['message' => '24 jam deadline terlampaui tanpa konfirmasi dari sitter.']
            );
        }
        
        $pdo->commit();
        return count($expiredChats);
        
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

// ============================================================================
// GET BROADCAST HISTORY FOR REQUEST
// ============================================================================

/**
 * Get broadcast history for analytics
 * 
 * @param PDO $pdo
 * @param int $requestId
 * @return array<string, mixed>
 */
function kakiempat_broadcast_bidding_v2_get_history(
    PDO $pdo,
    int $requestId
): array {
    $stmt = $pdo->prepare(
        'SELECT id, action, rebroadcast_count, trigger_reason, created_at 
         FROM kakiempa_v2_broadcast_history 
         WHERE request_id = ? 
         ORDER BY created_at ASC'
    );
    $stmt->execute([$requestId]);
    
    $history = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $history[] = [
            'action' => (string) $row['action'],
            'rebroadcast_count' => (int) $row['rebroadcast_count'],
            'trigger_reason' => (string) ($row['trigger_reason'] ?? ''),
            'timestamp' => (string) $row['created_at']
        ];
    }
    
    return [
        'request_id' => (string) $requestId,
        'history' => $history,
        'total_rebroadcasts' => count(array_filter($history, fn($h) => $h['action'] === 'rebroadcast'))
    ];
}
