<?php
declare(strict_types=1);

/**
 * Batch 3 — Admin v2 (founder only).
 *
 * GET  ?action=list_pending_sitters|list_sitters|list_owners|list_bookings
 * GET  ?action=list_pending_withdrawals
 * POST ?action=approve_sitter|reject_sitter|approve_withdrawal|reject_withdrawal
 */
require_once __DIR__ . '/lib/kakiempat_admin_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'list_pending_sitters':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_list_pending_sitters();
            break;
        case 'list_sitters':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_list_sitters();
            break;
        case 'list_owners':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_list_owners();
            break;
        case 'list_bookings':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_list_bookings();
            break;
        case 'approve_sitter':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_admin_v2_approve_sitter(v2ApiBody());
            break;
        case 'reject_sitter':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_admin_v2_reject_sitter(v2ApiBody());
            break;
        case 'approve_withdrawal':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_admin_v2_approve_withdrawal(v2ApiBody());
            break;
        case 'list_pending_withdrawals':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_list_pending_withdrawals();
            break;
        case 'get_launch_metrics':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_get_launch_metrics();
            break;
        case 'agent_health':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_admin_v2_agent_health();
            break;
        case 'reject_withdrawal':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_admin_v2_reject_withdrawal(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan list_pending_sitters, list_sitters, list_owners, list_bookings, '
                . 'list_pending_withdrawals, get_launch_metrics, agent_health, approve_sitter, reject_sitter, '
                . 'approve_withdrawal, atau reject_withdrawal.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('admin_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
