<?php
declare(strict_types=1);

/**
 * Batch 3 — Notifikasi in-app v2.
 *
 * GET  ?action=check_new | get_notifications
 * POST ?action=mark_read
 */
require_once __DIR__ . '/lib/kakiempat_notification_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'check_new':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_notification_v2_check_new();
            break;
        case 'get_notifications':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_notification_v2_get_notifications();
            break;
        case 'mark_read':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_notification_v2_mark_read(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan check_new, get_notifications, atau mark_read.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('notification_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
