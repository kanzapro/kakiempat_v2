<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_service_v2.php';
require_once __DIR__ . '/kakiempat_sitter_badges_v2.php';

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

    $existingMeta = [];
    $stmtExisting = $pdo->prepare(
        'SELECT profile_json FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmtExisting->execute([$auth['user_id']]);
    $existingRaw = $stmtExisting->fetchColumn();
    if ($existingRaw !== false) {
        $existingMeta = kakiempat_sitter_v2_decode_json((string) $existingRaw);
    }

    $profileMeta = [
        'services' => $serviceCodes,
        'latitude' => $latitude,
        'longitude' => $longitude,
        'bio' => $bio,
        'is_available' => array_key_exists('is_available', $existingMeta)
            ? ($existingMeta['is_available'] !== false)
            : true,
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

/** @param array<string, mixed> $body */
function kakiempat_sitter_v2_set_availability(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);

    $isAvailable = filter_var($body['is_available'] ?? true, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    if ($isAvailable === null) {
        v2ApiFail('invalid_availability', 'Status ketersediaan tidak valid.', 400);
    }

    $pdo = v2ApiPdo();
    $stmt = $pdo->prepare(
        'SELECT profile_json FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    $raw = $stmt->fetchColumn();
    if ($raw === false) {
        v2ApiFail('profile_not_found', 'Profil pengasuh belum ada.', 404);
    }

    $meta = kakiempat_sitter_v2_decode_json((string) $raw);
    $meta['is_available'] = $isAvailable;
    $jsonProfile = json_encode($meta, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

    $pdo->prepare(
        'UPDATE kakiempa_v2_sitter_profiles SET profile_json = ? WHERE user_id = ?',
    )->execute([$jsonProfile, $auth['user_id']]);

    kakiempat_sitter_v2_get_profile();
}

function kakiempat_sitter_v2_is_available(PDO $pdo, int $userId): bool
{
    $stmt = $pdo->prepare(
        'SELECT profile_json FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $raw = $stmt->fetchColumn();
    if ($raw === false) {
        return true;
    }
    $meta = kakiempat_sitter_v2_decode_json((string) $raw);

    return ($meta['is_available'] ?? true) !== false;
}

/** @param array<string, mixed> $body */
function kakiempat_sitter_v2_upload_verification(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);

    $ktp = trim((string) ($body['ktp_data'] ?? $body['ktp_image'] ?? ''));
    $selfie = trim((string) ($body['selfie_data'] ?? $body['selfie_image'] ?? ''));

    if ($ktp === '' || $selfie === '') {
        v2ApiFail('documents_required', 'Foto KTP dan selfie wajib diunggah.', 400);
    }
    if (strlen($ktp) > 2_000_000 || strlen($selfie) > 2_000_000) {
        v2ApiFail('image_too_large', 'Ukuran foto terlalu besar.', 413);
    }

    $pdo = v2ApiPdo();
    $stmt = $pdo->prepare(
        'SELECT profile_json FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    $raw = $stmt->fetchColumn();
    if ($raw === false) {
        v2ApiFail('profile_missing', 'Lengkapi profil pengasuh terlebih dahulu.', 400);
    }

    $meta = kakiempat_sitter_v2_decode_json((string) $raw);
    $meta['verification'] = [
        'ktp_data' => $ktp,
        'selfie_data' => $selfie,
        'uploaded_at' => date('Y-m-d H:i:s.u'),
    ];
    $jsonProfile = json_encode($meta, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

    $pdo->prepare(
        'UPDATE kakiempa_v2_sitter_profiles SET profile_json = ? WHERE user_id = ?',
    )->execute([$jsonProfile, $auth['user_id']]);

    v2ApiRespondData([
        'message' => 'Dokumen verifikasi berhasil diunggah.',
        'has_ktp' => true,
        'has_selfie' => true,
    ]);
}

function kakiempat_sitter_v2_submit_verification(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);

    $pdo = v2ApiPdo();
    $stmt = $pdo->prepare(
        'SELECT profile_json FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    $raw = $stmt->fetchColumn();
    if ($raw === false) {
        v2ApiFail('profile_missing', 'Lengkapi profil pengasuh terlebih dahulu.', 400);
    }

    $meta = kakiempat_sitter_v2_decode_json((string) $raw);
    $verification = $meta['verification'] ?? [];
    if (!is_array($verification)
        || empty($verification['ktp_data'])
        || empty($verification['selfie_data'])) {
        v2ApiFail(
            'documents_missing',
            'Unggah foto KTP dan selfie terlebih dahulu.',
            400,
        );
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

    $verification = $meta['verification'] ?? [];
    $hasKtp = is_array($verification) && !empty($verification['ktp_data']);
    $hasSelfie = is_array($verification) && !empty($verification['selfie_data']);
    $stats = kakiempat_sitter_badges_v2_stats($pdo, $userId);

    return [
        'profile' => [
            'bio' => $bio,
            'address' => $address,
            'latitude' => $meta['latitude'] ?? null,
            'longitude' => $meta['longitude'] ?? null,
            'status' => $status,
            'submitted_at' => $row['submitted_at'] ?? null,
            'is_verified' => $status === 'approved',
            'has_verification_docs' => $hasKtp && $hasSelfie,
            'is_available' => ($meta['is_available'] ?? true) !== false,
        ],
        'services' => array_values(array_map('strval', $services)),
        'onboarding_complete' => $profileComplete && $status !== 'draft',
        'needs_onboarding' => $status === 'draft' || !$profileComplete,
        'badges' => kakiempat_sitter_badges_v2_compute($pdo, $userId),
        'average_rating' => $stats['average_rating'],
        'completed_bookings' => $stats['completed_bookings'],
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
