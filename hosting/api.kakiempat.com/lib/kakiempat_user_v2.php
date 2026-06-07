<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_owner_v2.php';
require_once __DIR__ . '/kakiempat_sitter_v2.php';

/** GET — profil pemilik atau pengasuh sesuai role token. */
function kakiempat_user_v2_get_profile(): void
{
    $auth = v2ApiRequireAuth();
    $role = (string) ($auth['role'] ?? '');

    if ($role === 'sitter') {
        kakiempat_sitter_v2_get_profile();
        return;
    }
    if ($role === 'owner' || $role === 'founder') {
        kakiempat_owner_v2_get_profile();
        return;
    }

    v2ApiFail('forbidden', 'Role akun tidak didukung untuk profil pengguna.', 403);
}

/** POST — update profil pemilik atau pengasuh sesuai role token. */
function kakiempat_user_v2_update_profile(array $body): void
{
    $auth = v2ApiRequireAuth();
    $role = (string) ($auth['role'] ?? '');

    if ($role === 'sitter') {
        kakiempat_sitter_v2_save_profile($body);
        return;
    }
    if ($role === 'owner' || $role === 'founder') {
        kakiempat_owner_v2_save_profile($body);
        return;
    }

    v2ApiFail('forbidden', 'Role akun tidak didukung untuk update profil.', 403);
}
