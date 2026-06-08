<?php
declare(strict_types=1);

/**
 * Platform API — partner app registry & read-only integrator endpoints.
 *
 * POST ?action=admin_create_app | admin_approve_app
 * GET  ?action=admin_list_apps | partner_get_booking | retry_pending_events
 */
require_once __DIR__ . '/lib/kakiempat_platform_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'admin_create_app':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_platform_v2_admin_create_app(v2ApiBody());
            break;
        case 'admin_list_apps':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_platform_v2_admin_list_apps();
            break;
        case 'admin_approve_app':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_platform_v2_admin_approve_app(v2ApiBody());
            break;
        case 'partner_get_booking':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_platform_v2_partner_get_booking();
            break;
        case 'retry_pending_events':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_platform_v2_retry_pending_events();
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan admin_create_app, admin_list_apps, admin_approve_app, partner_get_booking, atau retry_pending_events.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('platform_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
