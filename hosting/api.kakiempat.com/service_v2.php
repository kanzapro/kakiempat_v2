<?php
declare(strict_types=1);

/**
 * Batch 1 — Katalog layanan v2 (kakiempa_v2_service_catalog).
 *
 * GET ?action=get_catalog|check_category_supply  (auth wajib)
 */
require_once __DIR__ . '/lib/kakiempat_service_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

if ($action === 'get_service_catalog') {
    $action = 'get_catalog';
}

try {
    switch ($action) {
        case 'get_catalog':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_service_v2_get_catalog();
            break;
        case 'check_category_supply':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_service_v2_check_category_supply();
            break;
        default:
            v2ApiFail('action_required', 'Gunakan GET ?action=get_catalog atau check_category_supply', 400);
    }
} catch (Throwable $e) {
    error_log('service_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
