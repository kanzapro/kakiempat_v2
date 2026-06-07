<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

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
