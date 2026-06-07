<?php
declare(strict_types=1);

/**
 * Cron re-engagement — notifikasi owner tidak booking > 14 hari.
 * Panggil: cron_reengage_v2.php?secret=... (sama pola migrate)
 */
require_once __DIR__ . '/v2_api_common.php';
require_once __DIR__ . '/lib/kakiempat_event_notifications.php';

header('Content-Type: application/json; charset=utf-8');

$secret = trim((string) ($_GET['secret'] ?? ''));
$configFile = __DIR__ . '/.migrate_secret.php';
$expected = '';
if (is_readable($configFile)) {
    $cfg = require $configFile;
    $expected = is_array($cfg) ? (string) ($cfg['secret'] ?? '') : '';
}
if ($expected === '' || !hash_equals($expected, $secret)) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'forbidden']);
    exit;
}

try {
    $pdo = v2ApiPdo();
    $stmt = $pdo->query(
        "SELECT u.id, u.name,
                MAX(b.created_at) AS last_booking_at
         FROM kakiempa_v2_users u
         LEFT JOIN kakiempa_v2_bookings b ON b.owner_user_id = u.id
         WHERE u.role IN ('owner', 'founder') AND u.is_active = 1
         GROUP BY u.id, u.name
         HAVING last_booking_at IS NULL
            OR last_booking_at < DATE_SUB(NOW(6), INTERVAL 14 DAY)",
    );

    $sent = 0;
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $userId = (int) ($row['id'] ?? 0);
        if ($userId < 1) {
            continue;
        }
        kakiempat_event_notifications_push(
            $pdo,
            $userId,
            'Milo kangen jalan-jalan nih 🐕',
            'Sudah lama tidak booking. Cari sitter sekarang?',
            null,
            'reengage',
        );
        $sent++;
    }

    echo json_encode([
        'ok' => true,
        'data' => ['notifications_sent' => $sent],
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    error_log('cron_reengage_v2: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'server_error']);
}
