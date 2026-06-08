<?php
declare(strict_types=1);

/**
 * Batch 1 — Profil pemilik & hewan v2 (kakiempa_v2).
 * BFF money-engine: GET ?action=get_dashboard (agregat home owner).
 *
 * POST ?action=save_profile
 * POST ?action=add_pet|update_pet|delete_pet
 * GET  ?action=get_profile|get_dashboard|get_pet_timeline
 */
require_once __DIR__ . '/lib/kakiempat_owner_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

$aliases = [
    'save_owner_profile' => 'save_profile',
    'get_owner_profile' => 'get_profile',
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
            kakiempat_owner_v2_save_profile(v2ApiBody());
            break;
        case 'add_pet':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_owner_v2_add_pet(v2ApiBody());
            break;
        case 'update_pet':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_owner_v2_update_pet(v2ApiBody());
            break;
        case 'delete_pet':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_owner_v2_delete_pet(v2ApiBody());
            break;
        case 'get_profile':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_owner_v2_get_profile();
            break;
        case 'get_dashboard':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_owner_v2_get_dashboard();
            break;
        case 'get_pet_timeline':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_owner_v2_get_pet_timeline();
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan save_profile, add_pet, update_pet, delete_pet, get_profile, get_dashboard, atau get_pet_timeline.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('owner_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
