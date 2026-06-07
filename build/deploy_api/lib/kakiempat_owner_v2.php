<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @param array<string, mixed> $body */
function kakiempat_owner_v2_save_profile(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);

    $address = trim((string) ($body['address'] ?? ''));
    $lat = $body['latitude'] ?? null;
    $lng = $body['longitude'] ?? null;
    $latitude = is_numeric($lat) ? (float) $lat : null;
    $longitude = is_numeric($lng) ? (float) $lng : null;

    if ($address === '') {
        v2ApiFail('invalid_address', 'Alamat wajib diisi.', 400);
    }

    $pdo = v2ApiPdo();
    $user = v2ApiFetchUser($pdo, $auth['user_id']);
    if ($user === null) {
        v2ApiFail('user_not_found', 'Akun tidak ditemukan.', 404);
    }

    $name = (string) ($user['name'] ?? '');
    $phone = (string) ($user['whatsapp'] ?? $auth['phone']);

    $stmt = $pdo->prepare(
        'SELECT user_id FROM kakiempa_v2_owner_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    if ($stmt->fetchColumn()) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_owner_profiles
             SET home_address = ?, latitude = ?, longitude = ?,
                 display_name = ?, whatsapp = ?
             WHERE user_id = ?',
        )->execute([$address, $latitude, $longitude, $name, $phone, $auth['user_id']]);
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_owner_profiles
                (user_id, display_name, whatsapp, home_address, latitude, longitude)
             VALUES (?, ?, ?, ?, ?, ?)',
        )->execute([$auth['user_id'], $name, $phone, $address, $latitude, $longitude]);
    }

    kakiempat_owner_v2_get_profile();
}

/** @param array<string, mixed> $body */
function kakiempat_owner_v2_add_pet(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);

    $name = trim((string) ($body['name'] ?? ''));
    $species = trim((string) ($body['species'] ?? ''));
    if ($name === '') {
        v2ApiFail('invalid_name', 'Nama hewan wajib diisi.', 400);
    }
    if ($species === '') {
        v2ApiFail('invalid_species', 'Spesies wajib diisi.', 400);
    }

    $breed = trim((string) ($body['breed'] ?? ''));
    $age = trim((string) ($body['age'] ?? ''));
    $weightRaw = $body['weight'] ?? null;
    $weight = is_numeric($weightRaw) ? (float) $weightRaw : null;
    $notes = trim((string) ($body['notes'] ?? ''));

    $pdo = v2ApiPdo();
    $pdo->prepare(
        'INSERT INTO kakiempa_v2_pets
            (owner_user_id, name, species, breed, age_label, weight_kg, behavior_notes)
         VALUES (?, ?, ?, ?, ?, ?, ?)',
    )->execute([
        $auth['user_id'],
        $name,
        $species,
        $breed !== '' ? $breed : null,
        $age !== '' ? $age : null,
        $weight,
        $notes !== '' ? $notes : null,
    ]);

    $petId = (int) $pdo->lastInsertId();
    v2ApiRespondData([
        'pet' => kakiempat_owner_v2_format_pet([
            'id' => $petId,
            'name' => $name,
            'species' => $species,
            'breed' => $breed,
            'age_label' => $age,
            'weight_kg' => $weight,
            'behavior_notes' => $notes,
        ]),
        'message' => 'Hewan berhasil ditambahkan.',
    ], 201);
}

/** @param array<string, mixed> $body */
function kakiempat_owner_v2_update_pet(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);

    $petId = (int) ($body['pet_id'] ?? $body['id'] ?? 0);
    if ($petId < 1) {
        v2ApiFail('invalid_pet_id', 'pet_id wajib.', 400);
    }

    $pdo = v2ApiPdo();
    $check = $pdo->prepare(
        'SELECT id FROM kakiempa_v2_pets WHERE id = ? AND owner_user_id = ? LIMIT 1',
    );
    $check->execute([$petId, $auth['user_id']]);
    if (!$check->fetchColumn()) {
        v2ApiFail('pet_not_found', 'Hewan tidak ditemukan.', 404);
    }

    $name = trim((string) ($body['name'] ?? ''));
    $species = trim((string) ($body['species'] ?? ''));
    if ($name === '') {
        v2ApiFail('invalid_name', 'Nama hewan wajib diisi.', 400);
    }
    if ($species === '') {
        v2ApiFail('invalid_species', 'Spesies wajib diisi.', 400);
    }

    $breed = trim((string) ($body['breed'] ?? ''));
    $age = trim((string) ($body['age'] ?? ''));
    $weightRaw = $body['weight'] ?? null;
    $weight = is_numeric($weightRaw) ? (float) $weightRaw : null;
    $notes = trim((string) ($body['notes'] ?? ''));

    $pdo->prepare(
        'UPDATE kakiempa_v2_pets
         SET name = ?, species = ?, breed = ?, age_label = ?, weight_kg = ?, behavior_notes = ?
         WHERE id = ? AND owner_user_id = ?',
    )->execute([
        $name,
        $species,
        $breed !== '' ? $breed : null,
        $age !== '' ? $age : null,
        $weight,
        $notes !== '' ? $notes : null,
        $petId,
        $auth['user_id'],
    ]);

    v2ApiRespondData([
        'pet' => kakiempat_owner_v2_format_pet([
            'id' => $petId,
            'name' => $name,
            'species' => $species,
            'breed' => $breed,
            'age_label' => $age,
            'weight_kg' => $weight,
            'behavior_notes' => $notes,
        ]),
        'message' => 'Data hewan diperbarui.',
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_owner_v2_delete_pet(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);

    $petId = (int) ($body['pet_id'] ?? $body['id'] ?? 0);
    if ($petId < 1) {
        v2ApiFail('invalid_pet_id', 'pet_id wajib.', 400);
    }

    $pdo = v2ApiPdo();
    $stmt = $pdo->prepare(
        'DELETE FROM kakiempa_v2_pets WHERE id = ? AND owner_user_id = ?',
    );
    $stmt->execute([$petId, $auth['user_id']]);
    if ($stmt->rowCount() < 1) {
        v2ApiFail('pet_not_found', 'Hewan tidak ditemukan.', 404);
    }

    v2ApiRespondData([
        'pet_id' => (string) $petId,
        'message' => 'Hewan dihapus.',
    ]);
}

function kakiempat_owner_v2_get_profile(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    v2ApiRespondData(kakiempat_owner_v2_build_profile_payload(v2ApiPdo(), $auth['user_id']));
}

/** @return array<string, mixed> */
function kakiempat_owner_v2_build_profile_payload(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare(
        'SELECT home_address, latitude, longitude, display_name, whatsapp
         FROM kakiempa_v2_owner_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $profileRow = $stmt->fetch(PDO::FETCH_ASSOC);

    $petStmt = $pdo->prepare(
        'SELECT id, name, species, breed, age_label, weight_kg, behavior_notes
         FROM kakiempa_v2_pets WHERE owner_user_id = ? ORDER BY created_at ASC',
    );
    $petStmt->execute([$userId]);
    $pets = [];
    while ($row = $petStmt->fetch(PDO::FETCH_ASSOC)) {
        if (is_array($row)) {
            $pets[] = kakiempat_owner_v2_format_pet($row);
        }
    }

    $address = trim((string) ($profileRow['home_address'] ?? ''));
    $onboardingComplete = $address !== '' && count($pets) > 0;

    return [
        'profile' => $profileRow ? [
            'address' => $address,
            'latitude' => $profileRow['latitude'] ?? null,
            'longitude' => $profileRow['longitude'] ?? null,
            'full_name' => (string) ($profileRow['display_name'] ?? ''),
            'contact_phone' => (string) ($profileRow['whatsapp'] ?? ''),
        ] : null,
        'pets' => $pets,
        'onboarding_complete' => $onboardingComplete,
        'needs_onboarding' => !$onboardingComplete,
    ];
}

function kakiempat_owner_v2_get_dashboard(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();
    $userId = $auth['user_id'];

    require_once __DIR__ . '/kakiempat_service_v2.php';
    require_once __DIR__ . '/kakiempat_booking_v2.php';
    require_once __DIR__ . '/kakiempat_marketplace_v2.php';

    $user = v2ApiFetchUser($pdo, $userId);
    $profilePayload = kakiempat_owner_v2_build_profile_payload($pdo, $userId);
    $catalogPayload = kakiempat_service_v2_build_catalog_payload($pdo);
    $bookings = kakiempat_booking_v2_fetch_owner_bookings($pdo, $userId);
    $requests = kakiempat_marketplace_v2_fetch_owner_requests($pdo, $userId, 'active');
    $recommendations = kakiempat_owner_v2_build_recommendations($pdo, $userId, $bookings);

    v2ApiRespondData([
        'owner' => $profilePayload,
        'user_name' => trim((string) ($user['name'] ?? '')),
        'catalog' => $catalogPayload,
        'bookings' => $bookings,
        'requests' => $requests,
        'recommendations' => $recommendations,
        'counts' => [
            'bookings' => count($bookings),
            'requests' => count($requests),
            'services' => (int) ($catalogPayload['total'] ?? 0),
        ],
    ]);
}

/**
 * Rekomendasi rule-based (tanpa ML) untuk fase growth super-app.
 *
 * @param list<array<string, mixed>> $bookings
 * @return list<array<string, mixed>>
 */
function kakiempat_owner_v2_build_recommendations(PDO $pdo, int $userId, array $bookings): array
{
    $items = [];

    $completed = array_values(array_filter(
        $bookings,
        static fn(array $b): bool => strtolower((string) ($b['status'] ?? '')) === 'completed',
    ));
    if ($completed !== []) {
        usort($completed, static function (array $a, array $b): int {
            return strcmp((string) ($b['created_at'] ?? ''), (string) ($a['created_at'] ?? ''));
        });
        $last = $completed[0];
        $sitterId = (string) ($last['sitter_user_id'] ?? '');
        $sitterName = (string) ($last['sitter_name'] ?? '');
        if ($sitterId !== '') {
            $items[] = [
                'kind' => 'rebook_sitter',
                'title' => 'Pesan ulang pengasuh terakhir',
                'subtitle' => $sitterName !== '' ? $sitterName : 'Pengasuh favorit Anda',
                'action' => 'open_catalog',
                'payload' => ['sitter_user_id' => $sitterId],
            ];
        }
    }

    $stmt = $pdo->query(
        "SELECT service_code, COUNT(*) AS cnt
         FROM kakiempa_v2_bookings
         WHERE LOWER(status) = 'completed'
         GROUP BY service_code
         ORDER BY cnt DESC
         LIMIT 1",
    );
    $popular = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : false;
    if (is_array($popular) && !empty($popular['service_code'])) {
        $items[] = [
            'kind' => 'popular_service',
            'title' => 'Layanan populer di Kaki Empat',
            'subtitle' => (string) $popular['service_code'],
            'action' => 'open_service',
            'payload' => ['service_code' => (string) $popular['service_code']],
        ];
    }

    $petStmt = $pdo->prepare(
        'SELECT species FROM kakiempa_v2_pets WHERE owner_user_id = ? LIMIT 1',
    );
    $petStmt->execute([$userId]);
    $species = (string) ($petStmt->fetchColumn() ?: '');
    if ($species !== '') {
        $items[] = [
            'kind' => 'pet_care_tip',
            'title' => 'Perawatan untuk hewan Anda',
            'subtitle' => 'Tips dan layanan untuk ' . $species,
            'action' => 'open_tips',
            'payload' => ['species' => $species],
        ];
    }

    return $items;
}

/** @param array<string, mixed> $row */
function kakiempat_owner_v2_format_pet(array $row): array
{
    return [
        'id' => (string) ($row['id'] ?? ''),
        'name' => (string) ($row['name'] ?? ''),
        'species' => (string) ($row['species'] ?? ''),
        'breed' => (string) ($row['breed'] ?? ''),
        'age' => (string) ($row['age_label'] ?? ''),
        'weight' => isset($row['weight_kg']) && $row['weight_kg'] !== null
            ? (float) $row['weight_kg']
            : null,
        'notes' => (string) ($row['behavior_notes'] ?? ''),
    ];
}
