<?php
declare(strict_types=1);

/**
 * Partner ecosystem — mini-services & business merchant registry.
 *
 * GET  ?action=list_services|list_businesses
 * POST ?action=register_business|admin_approve_business
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
        case 'list_businesses':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_partner_v2_list_businesses();
            break;
        case 'register_business':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_partner_v2_register_business(v2ApiBody());
            break;
        case 'admin_approve_business':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_partner_v2_admin_approve_business(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan list_services, list_businesses, register_business, atau admin_approve_business.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('partner_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
