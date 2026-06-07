<?php
declare(strict_types=1);

/**
 * Polling notifikasi in-app — ambil semua unread, auto mark is_read=1.
 *
 * GET ?user_id=N (harus cocok dengan Bearer token)
 * Response: {"ok":true,"count":1,"data":[{"id","title","message","created_at",...}]}
 */
require_once __DIR__ . '/lib/kakiempat_event_notifications.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Native-Session');
header('Access-Control-Max-Age: 86400');

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
if ($method === 'OPTIONS') {
    http_response_code(204);
    exit;
}
if ($method !== 'GET') {
    v2ApiFail('method_not_allowed', 'Gunakan GET.', 405);
}

try {
    $pdo = v2ApiPdo();
} catch (Throwable) {
    v2ApiFail('db_unavailable', 'Database tidak tersedia.', 503);
}

kakiempat_event_notifications_api_poll_unread($pdo);
