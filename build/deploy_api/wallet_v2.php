<?php
declare(strict_types=1);

/**
 * Wallet v2 — saldo & penarikan sitter.
 *
 * GET  ?action=get_balance|get_ledger
 * POST ?action=request_withdrawal
 */
require_once __DIR__ . '/v2_api_common.php';
require_once __DIR__ . '/lib/kakiempat_wallet_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

$aliases = [
    'request_withdraw' => 'request_withdrawal',
];
if (isset($aliases[$action])) {
    $action = $aliases[$action];
}

try {
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();
    $userId = $auth['user_id'];

    switch ($action) {
        case 'get_balance':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $balance = kakiempat_wallet_v2_balance($pdo, $userId);
            $pending = kakiempat_wallet_v2_pending_withdrawal_sum($pdo, $userId);
            v2ApiRespondData([
                'balance' => $balance,
                'pending_withdrawals' => $pending,
                'available' => $balance - $pending,
            ]);
            break;

        case 'get_ledger':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_wallet_v2_get_summary($pdo, $userId);
            break;

        case 'request_withdrawal':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_wallet_v2_request_withdraw($pdo, $userId, v2ApiBody());
            break;

        default:
            v2ApiFail(
                'action_required',
                'Gunakan get_balance, get_ledger, atau request_withdrawal.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('wallet_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
