<?php
declare(strict_types=1);

/**
 * Bisnis v2 — laporan penghasilan, target, promosi sitter.
 *
 * GET  ?action=get_earnings_report
 * GET  ?action=get_achievements
 * GET  ?action=list_my_promotions
 * POST ?action=create_promotion
 */
require_once __DIR__ . '/lib/kakiempat_business_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();

    switch ($action) {
        case 'get_earnings_report':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_business_v2_earnings_report($pdo, $auth['user_id']);
            break;
        case 'get_achievements':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_business_v2_get_achievements($pdo, $auth['user_id']);
            break;
        case 'list_my_promotions':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_business_v2_list_my_promotions($pdo, $auth['user_id']);
            break;
        case 'create_promotion':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_business_v2_create_promotion($pdo, $auth['user_id'], v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan get_earnings_report, get_achievements, list_my_promotions, atau create_promotion.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('business_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
