<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @return list<string> */
function kakiempat_kecamatan_v2_allowed(): array
{
    return [
        'Denpasar Barat',
        'Denpasar Timur',
        'Denpasar Selatan',
        'Denpasar Utara',
    ];
}

/** @return list<array{code: string, label: string}> */
function kakiempat_kecamatan_v2_list_payload(): array
{
    $items = [];
    foreach (kakiempat_kecamatan_v2_allowed() as $name) {
        $items[] = ['code' => $name, 'label' => $name];
    }

    return $items;
}

function kakiempat_kecamatan_v2_is_valid(?string $input): bool
{
    if ($input === null || trim($input) === '') {
        return false;
    }

    return in_array(trim($input), kakiempat_kecamatan_v2_allowed(), true);
}

function kakiempat_kecamatan_v2_normalize(?string $input): ?string
{
    if ($input === null) {
        return null;
    }
    $trimmed = trim($input);
    if ($trimmed === '') {
        return null;
    }

    return kakiempat_kecamatan_v2_is_valid($trimmed) ? $trimmed : null;
}

function kakiempat_kecamatan_v2_require(?string $input): string
{
    $normalized = kakiempat_kecamatan_v2_normalize($input);
    if ($normalized === null) {
        v2ApiFail(
            'invalid_kecamatan',
            'Kaki Empat saat ini baru beroperasi secara eksklusif di 4 Kecamatan Kota Denpasar.',
            400,
        );
    }

    return $normalized;
}

function kakiempat_kecamatan_v2_has_column(PDO $pdo, string $table): bool
{
    return v2ApiColumnExists($pdo, $table, 'kecamatan');
}

function kakiempat_kecamatan_v2_get_sitter(PDO $pdo, int $userId): ?string
{
    if (!kakiempat_kecamatan_v2_has_column($pdo, 'kakiempa_v2_sitter_profiles')) {
        return null;
    }
    $stmt = $pdo->prepare(
        'SELECT kecamatan FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $value = $stmt->fetchColumn();
    if ($value === false || $value === null) {
        return null;
    }

    return kakiempat_kecamatan_v2_normalize((string) $value);
}

function kakiempat_kecamatan_v2_get_owner(PDO $pdo, int $userId): ?string
{
    if (!kakiempat_kecamatan_v2_has_column($pdo, 'kakiempa_v2_owner_profiles')) {
        return null;
    }
    $stmt = $pdo->prepare(
        'SELECT kecamatan FROM kakiempa_v2_owner_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $value = $stmt->fetchColumn();
    if ($value === false || $value === null) {
        return null;
    }

    return kakiempat_kecamatan_v2_normalize((string) $value);
}

function kakiempat_kecamatan_v2_count_sitters(
    PDO $pdo,
    string $kecamatan,
    string $serviceCode,
): int {
    if (!kakiempat_kecamatan_v2_has_column($pdo, 'kakiempa_v2_sitter_profiles')) {
        return 0;
    }

    $kecamatan = kakiempat_kecamatan_v2_require($kecamatan);
    $serviceJson = json_encode($serviceCode, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

    $stmt = $pdo->prepare(
        "SELECT COUNT(*) FROM kakiempa_v2_sitter_profiles sp
         WHERE sp.status = 'approved'
           AND sp.kecamatan = ?
           AND JSON_CONTAINS(sp.profile_json, ?, '$.services')
           AND (
             JSON_EXTRACT(sp.profile_json, '$.is_available') IS NULL
             OR JSON_EXTRACT(sp.profile_json, '$.is_available') = true
           )",
    );
    $stmt->execute([$kecamatan, $serviceJson]);

    return (int) ($stmt->fetchColumn() ?: 0);
}
