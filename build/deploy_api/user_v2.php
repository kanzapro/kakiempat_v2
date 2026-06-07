<?php
declare(strict_types=1);

/**
 * Profil pengguna v2 — owner & sitter (facade).
 *
 * GET  ?action=get_profile|get_referral_code|get_loyalty_points
 * POST ?action=update_profile|redeem_loyalty
 */
require_once __DIR__ . '/lib/kakiempat_user_v2.php';
require_once __DIR__ . '/lib/kakiempat_loyalty_v2.php';
require_once __DIR__ . '/lib/kakiempat_referral_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

$aliases = [
    'save_profile' => 'update_profile',
    'get_owner_profile' => 'get_profile',
    'get_sitter_profile' => 'get_profile',
];
if (isset($aliases[$action])) {
    $action = $aliases[$action];
}

try {
    switch ($action) {
        case 'get_profile':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_user_v2_get_profile();
            break;
        case 'get_referral_code':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            kakiempat_referral_v2_get_code(v2ApiPdo(), $auth['user_id']);
            break;
        case 'get_loyalty_points':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            $auth = v2ApiRequireAuth();
            kakiempat_loyalty_v2_get_profile(v2ApiPdo(), $auth['user_id']);
            break;
        case 'redeem_loyalty':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            $auth = v2ApiRequireAuth();
            kakiempat_loyalty_v2_redeem(v2ApiPdo(), $auth['user_id'], v2ApiBody());
            break;
        case 'update_profile':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_user_v2_update_profile(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan get_profile, get_referral_code, get_loyalty_points, update_profile, atau redeem_loyalty.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('user_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
