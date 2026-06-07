<?php
declare(strict_types=1);

/**
 * Batch 3 — Chat v2 (kakiempa_v2_messages).
 *
 * POST ?action=send_message
 * GET  ?action=get_messages&booking_id=
 * GET  ?action=check_new_messages&booking_id=&since=
 */
require_once __DIR__ . '/lib/kakiempat_chat_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'send_message':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_chat_v2_send_message(v2ApiBody());
            break;
        case 'get_messages':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_chat_v2_get_messages();
            break;
        case 'check_new_messages':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_chat_v2_check_new_messages();
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan send_message, get_messages, atau check_new_messages.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('chat_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
