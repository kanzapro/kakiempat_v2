<?php
declare(strict_types=1);

/**
 * Broadcast Events API - Real-time polling & SSE streaming
 *
 * Endpoints:
 * GET ?action=poll - Poll for new events (long-polling, 30s timeout)
 * GET ?action=stream - SSE stream for real-time events (keep-alive)
 */

require_once __DIR__ . '/v2_api_common.php';
require_once __DIR__ . '/lib/kakiempat_broadcast_bidding_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'poll':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_broadcast_events_poll();
            break;

        case 'stream':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_broadcast_events_stream();
            break;

        default:
            v2ApiFail(
                'action_required',
                'Gunakan poll atau stream.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('broadcast_events: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}

// ============================================================================
// POLL ENDPOINT (Long-polling with timeout)
// ============================================================================

function kakiempat_broadcast_events_poll(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();
    
    $lastPollStr = trim((string) ($_GET['last_poll'] ?? ''));
    $lastPoll = 0;
    if ($lastPollStr !== '' && is_numeric($lastPollStr)) {
        $lastPoll = (int) $lastPollStr;
    }
    
    // Poll with 30 second timeout (check every 2 seconds)
    $timeoutAt = time() + 30;
    $pollCount = 0;
    $maxPolls = 15; // 15 x 2s = 30s timeout
    
    while ($pollCount < $maxPolls) {
        try {
            $events = kakiempat_broadcast_bidding_v2_poll_events(
                $pdo,
                $auth['user_id'],
                $lastPoll > 0 ? $lastPoll : null
            );
            
            if ($events['count'] > 0) {
                // Found events, return immediately
                v2ApiRespondData([
                    'ok' => true,
                    'events' => $events['events'],
                    'count' => $events['count'],
                    'timestamp' => time(),
                    'polled_at' => $events['timestamp_polled']
                ]);
                return;
            }
        } catch (Throwable) {
            // Ignore query errors on poll
        }
        
        // No events, sleep and retry
        sleep(2);
        $pollCount++;
    }
    
    // Timeout - return empty result
    v2ApiRespondData([
        'ok' => true,
        'events' => [],
        'count' => 0,
        'timestamp' => time(),
        'message' => 'No events within 30 seconds'
    ]);
}

// ============================================================================
// STREAM ENDPOINT (Server-Sent Events)
// ============================================================================

function kakiempat_broadcast_events_stream(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();
    
    // Set up SSE headers
    header('Content-Type: text/event-stream');
    header('Cache-Control: no-cache');
    header('Connection: keep-alive');
    header('X-Accel-Buffering: no'); // Disable nginx buffering
    header('Access-Control-Allow-Origin: *');
    
    // Send initial comment to keep connection alive
    echo ": Connected to event stream\n\n";
    flush();
    
    $lastPoll = time();
    $streamTimeout = 300; // 5 minutes
    $startTime = time();
    
    while (true) {
        // Check timeout
        if (time() - $startTime > $streamTimeout) {
            echo "event: timeout\n";
            echo "data: {\"message\":\"Stream timeout after 5 minutes\"}\n\n";
            flush();
            break;
        }
        
        try {
            $events = kakiempat_broadcast_bidding_v2_poll_events(
                $pdo,
                $auth['user_id'],
                $lastPoll
            );
            
            if ($events['count'] > 0) {
                foreach ($events['events'] as $event) {
                    echo "event: broadcast\n";
                    echo "data: " . json_encode($event, JSON_UNESCAPED_UNICODE) . "\n\n";
                    $lastPoll = time();
                }
                flush();
            } else {
                // Send heartbeat comment
                echo ": heartbeat\n\n";
                flush();
            }
        } catch (Throwable $e) {
            echo "event: error\n";
            echo "data: {\"error\":\"" . addslashes($e->getMessage()) . "\"}\n\n";
            flush();
        }
        
        // Poll every 3 seconds
        sleep(3);
    }
    
    exit;
}
