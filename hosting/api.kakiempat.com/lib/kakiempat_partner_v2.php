<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_kecamatan_v2.php';

function kakiempat_partner_v2_list_services(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'sitter', 'founder']);
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_partner_services')) {
        v2ApiRespondData(['services' => [], 'total' => 0]);
        return;
    }

    $category = trim((string) ($_GET['category'] ?? ''));
    $sql = 'SELECT id, code, name, category, description, logo_emoji,
                   action_type, action_url, sort_order
            FROM kakiempa_v2_partner_services
            WHERE is_active = 1';
    $params = [];
    if ($category !== '') {
        $sql .= ' AND category = ?';
        $params[] = $category;
    }
    $sql .= ' ORDER BY sort_order ASC, name ASC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $services = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $services[] = [
            'id' => (string) ($row['id'] ?? ''),
            'code' => (string) ($row['code'] ?? ''),
            'name' => (string) ($row['name'] ?? ''),
            'category' => (string) ($row['category'] ?? ''),
            'description' => (string) ($row['description'] ?? ''),
            'logo_emoji' => (string) ($row['logo_emoji'] ?? '🐾'),
            'action_type' => (string) ($row['action_type'] ?? 'external_url'),
            'action_url' => (string) ($row['action_url'] ?? ''),
        ];
    }

    v2ApiRespondData(['services' => $services, 'total' => count($services)]);
}

function kakiempat_partner_v2_list_businesses(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'sitter', 'founder', 'partner']);
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_business_profiles')) {
        v2ApiRespondData(['businesses' => [], 'total' => 0]);
        return;
    }

    $category = trim((string) ($_GET['category'] ?? ''));
    $kecamatan = kakiempat_kecamatan_v2_normalize((string) ($_GET['kecamatan'] ?? ''));
    $status = trim((string) ($_GET['status'] ?? 'approved'));

    $sql = 'SELECT b.id, b.user_id, b.legal_name, b.provider_type, b.status,
                   b.service_codes, l.label AS location_label, l.address, l.kecamatan
            FROM kakiempa_v2_business_profiles b
            LEFT JOIN kakiempa_v2_business_locations l
              ON l.business_id = b.id AND l.is_primary = 1
            WHERE b.status = ?';
    $params = [$status !== '' ? $status : 'approved'];

    if ($kecamatan !== null) {
        $sql .= ' AND l.kecamatan = ?';
        $params[] = $kecamatan;
    }

    $sql .= ' ORDER BY b.legal_name ASC LIMIT 100';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $businesses = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $codes = json_decode((string) ($row['service_codes'] ?? '[]'), true);
        if (!is_array($codes)) {
            $codes = [];
        }
        if ($category !== '' && !in_array($category, $codes, true)) {
            $catServices = kakiempat_partner_v2_codes_for_category($pdo, $category);
            if ($catServices === [] || array_intersect($codes, $catServices) === []) {
                continue;
            }
        }
        $businesses[] = [
            'id' => (string) ($row['id'] ?? ''),
            'user_id' => (string) ($row['user_id'] ?? ''),
            'legal_name' => (string) ($row['legal_name'] ?? ''),
            'provider_type' => (string) ($row['provider_type'] ?? 'business'),
            'status' => (string) ($row['status'] ?? ''),
            'service_codes' => array_values($codes),
            'location' => [
                'label' => (string) ($row['location_label'] ?? ''),
                'address' => (string) ($row['address'] ?? ''),
                'kecamatan' => (string) ($row['kecamatan'] ?? ''),
            ],
        ];
    }

    v2ApiRespondData(['businesses' => $businesses, 'total' => count($businesses)]);
}

/** @return list<string> */
function kakiempat_partner_v2_codes_for_category(PDO $pdo, string $category): array
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_service_catalog')) {
        return [];
    }
    $stmt = $pdo->prepare(
        'SELECT code FROM kakiempa_v2_service_catalog WHERE category = ? AND is_active = 1',
    );
    $stmt->execute([$category]);
    $codes = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (is_array($row) && !empty($row['code'])) {
            $codes[] = (string) $row['code'];
        }
    }

    return $codes;
}

/** @param array<string, mixed> $body */
function kakiempat_partner_v2_register_business(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'sitter', 'founder']);
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_business_profiles')) {
        v2ApiFail('schema_missing', 'Business profiles belum dimigrasi (025).', 503);
    }

    $legalName = trim((string) ($body['legal_name'] ?? ''));
    $providerType = trim((string) ($body['provider_type'] ?? 'business'));
    if (!in_array($providerType, ['individual', 'business'], true)) {
        $providerType = 'business';
    }
    $address = trim((string) ($body['address'] ?? ''));
    $kecamatan = kakiempat_kecamatan_v2_normalize((string) ($body['kecamatan'] ?? ''));
    $serviceCodes = $body['service_codes'] ?? [];
    if (!is_array($serviceCodes)) {
        $serviceCodes = [];
    }
    $serviceCodes = array_values(array_filter(array_map('strval', $serviceCodes)));

    if ($legalName === '') {
        v2ApiFail('invalid_name', 'Nama bisnis wajib diisi.', 400);
    }
    if ($address === '') {
        v2ApiFail('invalid_address', 'Alamat wajib diisi.', 400);
    }

    require_once __DIR__ . '/kakiempat_service_v2.php';
    if ($serviceCodes !== []) {
        kakiempat_service_v2_assert_valid_codes($pdo, $serviceCodes);
    }

    $codesJson = json_encode($serviceCodes, JSON_UNESCAPED_UNICODE);
    $userId = $auth['user_id'];

    $stmt = $pdo->prepare(
        'SELECT id FROM kakiempa_v2_business_profiles WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $existingId = $stmt->fetchColumn();

    if ($existingId) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_business_profiles
             SET legal_name = ?, provider_type = ?, service_codes = ?,
                 status = \'pending\', submitted_at = CURRENT_TIMESTAMP(6)
             WHERE user_id = ?',
        )->execute([$legalName, $providerType, $codesJson, $userId]);
        $businessId = (int) $existingId;
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_business_profiles
                (user_id, legal_name, provider_type, service_codes, status, submitted_at)
             VALUES (?, ?, ?, ?, \'pending\', CURRENT_TIMESTAMP(6))',
        )->execute([$userId, $legalName, $providerType, $codesJson]);
        $businessId = (int) $pdo->lastInsertId();
    }

    $locStmt = $pdo->prepare(
        'SELECT id FROM kakiempa_v2_business_locations
         WHERE business_id = ? AND is_primary = 1 LIMIT 1',
    );
    $locStmt->execute([$businessId]);
    $locId = $locStmt->fetchColumn();

    if ($locId) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_business_locations
             SET address = ?, kecamatan = ?, label = ?
             WHERE id = ?',
        )->execute([
            $address,
            $kecamatan,
            trim((string) ($body['location_label'] ?? 'Cabang utama')),
            $locId,
        ]);
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_business_locations
                (business_id, label, address, kecamatan, is_primary)
             VALUES (?, ?, ?, ?, 1)',
        )->execute([
            $businessId,
            trim((string) ($body['location_label'] ?? 'Cabang utama')),
            $address,
            $kecamatan,
        ]);
    }

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_user_roles (user_id, role) VALUES (?, \'partner\')
         ON DUPLICATE KEY UPDATE role = VALUES(role)',
    )->execute([$userId]);

    v2ApiRespondData([
        'business_id' => (string) $businessId,
        'status' => 'pending',
        'message' => 'Profil bisnis dikirim untuk verifikasi admin.',
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_partner_v2_admin_approve_business(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['admin', 'founder']);
    $pdo = v2ApiPdo();

    $businessId = (int) ($body['business_id'] ?? 0);
    if ($businessId < 1) {
        v2ApiFail('invalid_business_id', 'business_id wajib.', 400);
    }

    $pdo->prepare(
        'UPDATE kakiempa_v2_business_profiles
         SET status = \'approved\', approved_at = CURRENT_TIMESTAMP(6)
         WHERE id = ?',
    )->execute([$businessId]);

    v2ApiRespondData([
        'business_id' => (string) $businessId,
        'status' => 'approved',
        'message' => 'Bisnis partner disetujui.',
    ]);
}
