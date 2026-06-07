<?php
declare(strict_types=1);

/**
 * Batch 1 — Profil pemilik & hewan v2 (kakiempa_v2).
 *
 * POST ?action=save_profile
 * POST ?action=add_pet|update_pet|delete_pet
 * GET  ?action=get_profile
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
        default:
            v2ApiFail(
                'action_required',
                'Gunakan save_profile, add_pet, update_pet, delete_pet, atau get_profile.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('owner_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
