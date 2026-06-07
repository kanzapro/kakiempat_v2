<?php
declare(strict_types=1);

/**
 * Health check API v2 — DB connectivity.
 * GET /health.php → { ok, mysql_ok, service, version, ts }
 */
require_once __DIR__ . '/v2_api_common.php';

header('Content-Type: application/json; charset=utf-8');

$mysqlOk = false;
try {
    $pdo = v2ApiPdo();
    $pdo->query('SELECT 1');
    $mysqlOk = true;
} catch (Throwable) {
    $mysqlOk = false;
}

http_response_code($mysqlOk ? 200 : 503);
echo json_encode([
    'ok' => $mysqlOk,
    'service' => 'kakiempat_v2_api',
    'version' => '0.2.0',
    'mysql_ok' => $mysqlOk,
    'ts' => date('c'),
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
