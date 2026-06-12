<?php
declare(strict_types=1);

/**
 * Booking v2 — permintaan owner, terima/tolak sitter, lifecycle layanan.
 *
 * LEGACY ENDPOINTS:
 * POST ?action=create_request|accept_request|reject_request|sitter_confirm|sitter_en_route|
 *              start_booking|complete_booking|cancel_booking
 * GET  ?action=get_booking&booking_id= | list_my_bookings | list_incoming_requests
 *
 * NEW BIDDING & CHAT ENDPOINTS (v2):
 * POST ?action=select_bid | send_bid_chat_message | sitter_confirm_status | owner_agree_terms | rebroadcast_request
 * GET  ?action=get_bid_chat_messages | list_active_bid_chats | list_waiting_sitter_chats
 */
require_once __DIR__ . '/lib/kakiempat_booking_v2.php';
require_once __DIR__ . '/lib/kakiempat_bidding_chat_v2.php';
require_once __DIR__ . '/lib/kakiempat_broadcast_bidding_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        // ========== LEGACY ENDPOINTS ==========
        case 'create_request':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_create_request(v2ApiBody());
            break;
        case 'list_incoming_requests':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_booking_v2_list_incoming_requests();
            break;
        case 'accept_request':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_accept_request(v2ApiBody());
            break;
        case 'reject_request':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_reject_request(v2ApiBody());
            break;
        case 'get_booking':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_booking_v2_get_booking();
            break;
        case 'list_my_bookings':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_booking_v2_list_my_bookings();
            break;
        case 'sitter_confirm':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_sitter_confirm(v2ApiBody());
            break;
        case 'sitter_en_route':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_sitter_en_route(v2ApiBody());
            break;
        case 'start_booking':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_start_booking(v2ApiBody());
            break;
        case 'complete_booking':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_complete_booking(v2ApiBody());
            break;
        case 'cancel_booking':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_booking_v2_cancel_booking(v2ApiBody());
            break;

        // ========== NEW BIDDING & CHAT ENDPOINTS ==========
        
        case 'select_bid':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            $result = kakiempat_bidding_chat_v2_select_bid(
                v2ApiPdo(),
                $auth,
                (int) (v2ApiBody()['request_id'] ?? 0),
                (int) (v2ApiBody()['offer_id'] ?? 0)
            );
            v2ApiRespondData($result, 201);
            break;

        case 'send_bid_chat_message':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            $body = v2ApiBody();
            $result = kakiempat_bidding_chat_v2_send_message(
                v2ApiPdo(),
                $auth,
                (int) ($body['bid_chat_id'] ?? 0),
                (string) ($body['message'] ?? ''),
                (string) ($body['message_type'] ?? 'text')
            );
            v2ApiRespondData($result, 201);
            break;

        case 'sitter_confirm_status':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            $body = v2ApiBody();
            $result = kakiempat_bidding_chat_v2_sitter_confirm_status(
                v2ApiPdo(),
                $auth,
                (int) ($body['bid_chat_id'] ?? 0),
                (string) ($body['confirmation_status'] ?? ''),
                isset($body['message']) ? (string) $body['message'] : null
            );
            v2ApiRespondData($result);
            break;

        case 'owner_agree_terms':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            $body = v2ApiBody();
            $result = kakiempat_bidding_chat_v2_owner_agree_terms(
                v2ApiPdo(),
                $auth,
                (int) ($body['bid_chat_id'] ?? 0),
                isset($body['negotiated_price']) ? (int) $body['negotiated_price'] : null,
                isset($body['negotiated_scheduled_at']) ? (string) $body['negotiated_scheduled_at'] : null,
                isset($body['message']) ? (string) $body['message'] : null
            );
            v2ApiRespondData($result);
            break;

        case 'get_bid_chat_messages':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            $result = kakiempat_bidding_chat_v2_get_messages(
                v2ApiPdo(),
                $auth,
                (int) ($_GET['bid_chat_id'] ?? 0)
            );
            v2ApiRespondData($result);
            break;

        case 'list_active_bid_chats':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            v2ApiRequireRole($auth, ['owner', 'founder']);
            $result = kakiempat_bidding_chat_v2_list_active_chats_owner(
                v2ApiPdo(),
                $auth['user_id']
            );
            v2ApiRespondData($result);
            break;

        case 'list_waiting_sitter_chats':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            v2ApiRequireRole($auth, ['sitter', 'founder']);
            $result = kakiempat_bidding_chat_v2_list_waiting_sitter_chats(
                v2ApiPdo(),
                $auth['user_id']
            );
            v2ApiRespondData($result);
            break;

        case 'rebroadcast_request':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            v2ApiRequireRole($auth, ['owner', 'founder']);
            $body = v2ApiBody();
            $result = kakiempat_broadcast_bidding_v2_rebroadcast_request(
                v2ApiPdo(),
                (int) ($body['request_id'] ?? 0),
                (int) ($body['bid_chat_id'] ?? 0),
                (string) ($body['reason'] ?? 'no_agreement')
            );
            v2ApiRespondData($result);
            break;

        default:
            v2ApiFail(
                'action_required',
                'LEGACY: create_request, list_incoming_requests, accept_request, reject_request, '
                . 'get_booking, list_my_bookings, sitter_confirm, sitter_en_route, start_booking, '
                . 'complete_booking, cancel_booking. '
                . 'NEW: select_bid, send_bid_chat_message, sitter_confirm_status, owner_agree_terms, '
                . 'get_bid_chat_messages, list_active_bid_chats, list_waiting_sitter_chats, rebroadcast_request.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('booking_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
