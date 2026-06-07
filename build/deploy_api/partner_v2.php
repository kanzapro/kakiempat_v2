<?php
declare(strict_types=1);

/**
 * Partner / mini-service registry — super-app fase full.
 *
 * GET ?action=list_services[&category=health|commerce|grooming]
 */
require_once __DIR__ . '/lib/kakiempat_partner_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'list_services':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_partner_v2_list_services();
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan list_services.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('partner_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
