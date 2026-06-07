<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_owner_v2.php';

function kakiempat_pet_v2_list_pets(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $stmt = $pdo->prepare(
        'SELECT id, name, species, breed, age_label, weight_kg, behavior_notes
         FROM kakiempa_v2_pets WHERE owner_user_id = ? ORDER BY created_at ASC',
    );
    $stmt->execute([$auth['user_id']]);
    $pets = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (is_array($row)) {
            $pets[] = kakiempat_owner_v2_format_pet($row);
        }
    }

    v2ApiRespondData(['pets' => $pets, 'total' => count($pets)]);
}

function kakiempat_pet_v2_get_pet(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder', 'sitter', 'admin']);
    $pdo = v2ApiPdo();

    $petId = (int) ($_GET['pet_id'] ?? $_GET['id'] ?? 0);
    if ($petId < 1) {
        v2ApiFail('invalid_pet_id', 'Parameter pet_id wajib.', 400);
    }

    $stmt = $pdo->prepare(
        'SELECT id, owner_user_id, name, species, breed, age_label, weight_kg, behavior_notes
         FROM kakiempa_v2_pets WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$petId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('pet_not_found', 'Hewan tidak ditemukan.', 404);
    }

    $ownerId = (int) ($row['owner_user_id'] ?? 0);
    if ($auth['role'] === 'owner' || $auth['role'] === 'founder') {
        if ($ownerId !== $auth['user_id']) {
            v2ApiFail('forbidden', 'Akses ditolak.', 403);
        }
    } elseif ($auth['role'] === 'sitter') {
        $check = $pdo->prepare(
            'SELECT id FROM kakiempa_v2_bookings
             WHERE sitter_user_id = ? AND owner_user_id = ?
             LIMIT 1',
        );
        $check->execute([$auth['user_id'], $ownerId]);
        if (!$check->fetchColumn()) {
            v2ApiFail('forbidden', 'Hewan hanya dapat dilihat untuk booking aktif.', 403);
        }
    } elseif (!v2ApiIsAdmin($auth)) {
        v2ApiFail('forbidden', 'Akses ditolak.', 403);
    }

    v2ApiRespondData(['pet' => kakiempat_owner_v2_format_pet($row)]);
}

/** @param array<string, mixed> $body */
function kakiempat_pet_v2_create(array $body): void
{
    kakiempat_owner_v2_add_pet($body);
}

/** @param array<string, mixed> $body */
function kakiempat_pet_v2_update(array $body): void
{
    kakiempat_owner_v2_update_pet($body);
}

/** @param array<string, mixed> $body */
function kakiempat_pet_v2_delete(array $body): void
{
    kakiempat_owner_v2_delete_pet($body);
}
