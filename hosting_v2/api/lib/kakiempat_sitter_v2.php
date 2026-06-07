<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_service_v2.php';

/** @return array<string, mixed> */
function kakiempat_sitter_v2_decode_json(?string $raw): array
{
    if ($raw === null || $raw === '') {
        return [];
    }
    $decoded = json_decode($raw, true);

    return is_array($decoded) ? $decoded : [];
}

/** @param array<string, mixed> $body */
function kakiempat_sitter_v2_save_profile(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);

    $bio = trim((string) ($body['bio'] ?? ''));
    $address = trim((string) ($body['address'] ?? ''));
    $services = $body['services'] ?? [];
    if (!is_array($services)) {
        v2ApiFail('invalid_services', 'Daftar layanan tidak valid.', 400);
    }
    $serviceCodes = [];
    foreach ($services as $code) {
        $c = trim((string) $code);
        if ($c !== '') {
            $serviceCodes[] = $c;
        }
    }
    $serviceCodes = array_values(array_unique($serviceCodes));

    $lat = $body['latitude'] ?? null;
    $lng = $body['longitude'] ?? null;
    $latitude = is_numeric($lat) ? (float) $lat : null;
    $longitude = is_numeric($lng) ? (float) $lng : null;

    if ($address === '') {
        v2ApiFail('invalid_address', 'Alamat wajib diisi.', 400);
    }

    $pdo = v2ApiPdo();
    if ($serviceCodes !== []) {
        kakiempat_service_v2_assert_valid_codes($pdo, $serviceCodes);
    }

    $user = v2ApiFetchUser($pdo, $auth['user_id']);
    if ($user === null) {
        v2ApiFail('user_not_found', 'Akun tidak ditemukan.', 404);
    }

    $profileMeta = [
        'services' => $serviceCodes,
        'latitude' => $latitude,
        'longitude' => $longitude,
        'bio' => $bio,
    ];
    $jsonProfile = json_encode($profileMeta, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $name = (string) ($user['name'] ?? 'Pengasuh');
    $phone = (string) ($user['whatsapp'] ?? $auth['phone']);

    $stmt = $pdo->prepare(
        'SELECT user_id FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    if ($stmt->fetchColumn()) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_sitter_profiles
             SET address = ?, profile_json = ?,
                 display_name = ?, legal_name = ?, whatsapp = ?
             WHERE user_id = ?',
        )->execute([$address, $jsonProfile, $name, $name, $phone, $auth['user_id']]);
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_sitter_profiles
                (user_id, display_name, legal_name, whatsapp, address, status, profile_json)
             VALUES (?, ?, ?, ?, ?, ?, ?)',
        )->execute([$auth['user_id'], $name, $name, $phone, $address, 'draft', $jsonProfile]);
    }

    kakiempat_sitter_v2_get_profile();
}

function kakiempat_sitter_v2_submit_verification(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);

    $pdo = v2ApiPdo();
    $stmt = $pdo->prepare(
        'SELECT user_id FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    if (!$stmt->fetchColumn()) {
        v2ApiFail('profile_missing', 'Lengkapi profil pengasuh terlebih dahulu.', 400);
    }

    $pdo->prepare(
        'UPDATE kakiempa_v2_sitter_profiles
         SET status = ?, submitted_at = NOW(6)
         WHERE user_id = ?',
    )->execute(['pending_verification', $auth['user_id']]);

    v2ApiRespondData([
        'message' => 'Profil dikirim untuk verifikasi. Tim Kaki Empat akan meninjau segera.',
        'status' => 'pending_verification',
    ]);
}

function kakiempat_sitter_v2_get_profile(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();
    $payload = kakiempat_sitter_v2_load_profile_row($pdo, $auth['user_id']);
    if ($payload === null) {
        v2ApiRespondData([
            'profile' => null,
            'services' => [],
            'onboarding_complete' => false,
            'needs_onboarding' => true,
        ]);

        return;
    }
    v2ApiRespondData($payload);
}

/** @return array<string, mixed>|null */
function kakiempat_sitter_v2_load_profile_row(PDO $pdo, int $userId): ?array
{
    $stmt = $pdo->prepare(
        'SELECT address, profile_json, status, submitted_at
         FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        return null;
    }

    $meta = kakiempat_sitter_v2_decode_json(
        isset($row['profile_json']) ? (string) $row['profile_json'] : null,
    );
    $services = $meta['services'] ?? [];
    if (!is_array($services)) {
        $services = [];
    }
    $status = (string) ($row['status'] ?? 'draft');
    $bio = trim((string) ($meta['bio'] ?? ''));
    $address = trim((string) ($row['address'] ?? ''));
    $profileComplete = $address !== '' && $bio !== '' && count($services) > 0;

    return [
        'profile' => [
            'bio' => $bio,
            'address' => $address,
            'latitude' => $meta['latitude'] ?? null,
            'longitude' => $meta['longitude'] ?? null,
            'status' => $status,
            'submitted_at' => $row['submitted_at'] ?? null,
        ],
        'services' => array_values(array_map('strval', $services)),
        'onboarding_complete' => $profileComplete && $status !== 'draft',
        'needs_onboarding' => $status === 'draft' || !$profileComplete,
    ];
}

/** @return list<string> */
function kakiempat_sitter_v2_service_codes(PDO $pdo, int $userId): array
{
    $stmt = $pdo->prepare(
        'SELECT profile_json FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $raw = $stmt->fetchColumn();
    if ($raw === false) {
        return [];
    }
    $meta = kakiempat_sitter_v2_decode_json((string) $raw);
    $services = $meta['services'] ?? [];
    if (!is_array($services)) {
        return [];
    }

    return array_values(array_filter(array_map('strval', $services)));
}

function kakiempat_sitter_v2_require_approved(PDO $pdo, int $userId): void
{
    $stmt = $pdo->prepare(
        'SELECT status FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $status = (string) ($stmt->fetchColumn() ?: '');
    if ($status !== 'approved') {
        v2ApiFail(
            'sitter_not_approved',
            'Profil pengasuh belum diverifikasi. Tunggu persetujuan admin.',
            403,
        );
    }
}
