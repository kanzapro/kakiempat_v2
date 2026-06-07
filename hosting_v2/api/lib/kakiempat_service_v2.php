<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @return array<string, array{code: string, title: string, sort_order: int}> */
function kakiempat_service_v2_load_categories(PDO $pdo): array
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_service_categories')) {
        return [];
    }
    $stmt = $pdo->query(
        'SELECT code, title, sort_order FROM kakiempa_v2_service_categories ORDER BY sort_order ASC',
    );
    $map = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $code = (string) ($row['code'] ?? '');
        if ($code === '') {
            continue;
        }
        $map[$code] = [
            'code' => $code,
            'title' => (string) ($row['title'] ?? $code),
            'sort_order' => (int) ($row['sort_order'] ?? 0),
        ];
    }

    return $map;
}

function kakiempat_service_v2_get_catalog(): void
{
    v2ApiRequireAuth();

    $pdo = v2ApiPdo();
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_service_catalog')) {
        v2ApiFail('schema_missing', 'Katalog layanan belum tersedia.', 503);
    }

    $categories = kakiempat_service_v2_load_categories($pdo);
    $hasCategory = v2ApiColumnExists($pdo, 'kakiempa_v2_service_catalog', 'category');
    $hasSort = v2ApiColumnExists($pdo, 'kakiempa_v2_service_catalog', 'sort_order');

    $categoryCol = $hasCategory ? ', category' : '';
    $sortCol = $hasSort ? ', sort_order' : '';
    $orderBy = $hasSort ? 'sort_order ASC, title ASC' : 'title ASC';

    $stmt = $pdo->query(
        'SELECT code, title, is_active' . $categoryCol . $sortCol . '
         FROM kakiempa_v2_service_catalog
         ORDER BY ' . $orderBy,
    );

    $services = [];
    $byCategory = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $cat = $hasCategory ? trim((string) ($row['category'] ?? '')) : 'other';
        if ($cat === '') {
            $cat = 'other';
        }
        $catMeta = $categories[$cat] ?? [
            'code' => $cat,
            'title' => $cat,
            'sort_order' => 999,
        ];
        $item = [
            'code' => (string) $row['code'],
            'label' => (string) $row['title'],
            'category' => $cat,
            'category_label' => (string) $catMeta['title'],
            'enabled' => (int) ($row['is_active'] ?? 1) === 1,
            'sort_order' => (int) ($row['sort_order'] ?? 0),
        ];
        $services[] = $item;
        if (!isset($byCategory[$cat])) {
            $byCategory[$cat] = [
                'code' => $cat,
                'label' => (string) $catMeta['title'],
                'sort_order' => (int) $catMeta['sort_order'],
                'services' => [],
            ];
        }
        $byCategory[$cat]['services'][] = $item;
    }

    $categoryList = array_values($byCategory);
    usort(
        $categoryList,
        static fn(array $a, array $b): int => ($a['sort_order'] ?? 0) <=> ($b['sort_order'] ?? 0),
    );

    v2ApiRespondData([
        'total' => count($services),
        'services' => $services,
        'categories' => $categoryList,
    ]);
}

function kakiempat_service_v2_is_valid_code(PDO $pdo, string $code): bool
{
    $stmt = $pdo->prepare(
        'SELECT 1 FROM kakiempa_v2_service_catalog
         WHERE code = ? AND is_active = 1 LIMIT 1',
    );
    $stmt->execute([$code]);

    return (bool) $stmt->fetchColumn();
}

/** @param list<string> $codes */
function kakiempat_service_v2_assert_valid_codes(PDO $pdo, array $codes): void
{
    foreach ($codes as $code) {
        if (!kakiempat_service_v2_is_valid_code($pdo, $code)) {
            v2ApiFail('invalid_service', sprintf('Kode layanan tidak valid: %s', $code), 400);
        }
    }
}
