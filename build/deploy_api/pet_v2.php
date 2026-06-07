<?php
declare(strict_types=1);

/**
 * CRUD hewan peliharaan v2.
 *
 * GET  ?action=list_pets | get_pet&pet_id=
 * POST ?action=create|update|delete  (alias: add_pet, update_pet, delete_pet)
 */
require_once __DIR__ . '/lib/kakiempat_pet_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

$aliases = [
    'add_pet' => 'create',
    'update_pet' => 'update',
    'delete_pet' => 'delete',
];
if (isset($aliases[$action])) {
    $action = $aliases[$action];
}

try {
    switch ($action) {
        case 'list_pets':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_pet_v2_list_pets();
            break;
        case 'get_pet':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_pet_v2_get_pet();
            break;
        case 'create':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_pet_v2_create(v2ApiBody());
            break;
        case 'update':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_pet_v2_update(v2ApiBody());
            break;
        case 'delete':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_pet_v2_delete(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan list_pets, get_pet, create, update, atau delete.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('pet_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
