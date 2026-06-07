<?php
declare(strict_types=1);

/**
 * Batch 1 — Profil pengasuh v2 (kakiempa_v2).
 *
 * POST ?action=save_profile
 * POST ?action=submit_verification
 * GET  ?action=get_profile
 * GET  ?action=get_wallet
 * POST ?action=request_withdraw
 * GET  ?action=list_my_withdrawals
 */
require_once __DIR__ . '/lib/kakiempat_sitter_v2.php';
require_once __DIR__ . '/lib/kakiempat_wallet_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

$aliases = [
    'save_sitter_profile' => 'save_profile',
    'submit_sitter_verification' => 'submit_verification',
    'get_sitter_profile' => 'get_profile',
];
if (isset($aliases[$action])) {
    $action = $aliases[$action];
}

try {
    switch ($action) {
        case 'save_profile':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_sitter_v2_save_profile(v2ApiBody());
            break;
        case 'submit_verification':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_sitter_v2_submit_verification();
            break;
        case 'get_profile':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_sitter_v2_get_profile();
            break;
        case 'get_wallet':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            v2ApiRequireRole($auth, ['sitter', 'founder']);
            kakiempat_wallet_v2_get_summary(v2ApiPdo(), $auth['user_id']);
            break;
        case 'request_withdraw':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            v2ApiRequireRole($auth, ['sitter', 'founder']);
            kakiempat_wallet_v2_request_withdraw(v2ApiPdo(), $auth['user_id'], v2ApiBody());
            break;
        case 'list_my_withdrawals':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            v2ApiRequireRole($auth, ['sitter', 'founder']);
            kakiempat_wallet_v2_list_my_withdrawals(v2ApiPdo(), $auth['user_id']);
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan save_profile, submit_verification, get_profile, get_wallet, '
                . 'request_withdraw, atau list_my_withdrawals.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('sitter_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
