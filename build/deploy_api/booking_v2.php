<?php
declare(strict_types=1);

/**
 * Booking v2 — permintaan owner, terima/tolak sitter, lifecycle layanan.
 *
 * POST ?action=create_request|accept_request|reject_request|sitter_confirm|sitter_en_route|
 *              start_booking|complete_booking|cancel_booking
 * GET  ?action=get_booking&booking_id= | list_my_bookings | list_incoming_requests |
 *              list_by_owner | list_by_sitter
 */
require_once __DIR__ . '/lib/kakiempat_booking_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
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
        case 'list_by_owner':
        case 'list_by_sitter':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            if ($action === 'list_by_owner') {
                kakiempat_booking_v2_list_by_owner();
            } elseif ($action === 'list_by_sitter') {
                kakiempat_booking_v2_list_by_sitter();
            } else {
                kakiempat_booking_v2_list_my_bookings();
            }
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
        default:
            v2ApiFail(
                'action_required',
                'Gunakan create_request, list_incoming_requests, accept_request, reject_request, '
                . 'get_booking, list_my_bookings, list_by_owner, list_by_sitter, sitter_confirm, '
                . 'sitter_en_route, start_booking, '
                . 'complete_booking, cancel_booking.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('booking_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
