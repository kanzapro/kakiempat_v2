<?php
declare(strict_types=1);

/**
 * Jalankan migrasi SQL v2.
 * GET ?secret=...&file=001_core_tables.sql
 */
require_once __DIR__ . '/cors.php';

header('Content-Type: application/json; charset=utf-8');

$secretFile = __DIR__ . '/.migrate_v2_secret';
$configFile = __DIR__ . '/.mysql_v2.php';
if (!is_readable($secretFile) || !is_readable($configFile)) {
    http_response_code(503);
    echo json_encode(['ok' => false, 'error' => 'config_missing']);
    exit;
}

$secret = trim((string) file_get_contents($secretFile));
$given = (string) ($_GET['secret'] ?? '');
if ($secret === '' || !hash_equals($secret, $given)) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'secret_invalid']);
    exit;
}

$file = basename((string) ($_GET['file'] ?? '001_core_tables.sql'));
if (!preg_match('/^[0-9]{3}_[a-z0-9_]+\.sql$/', $file)) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => 'invalid_file']);
    exit;
}

$sqlFile = __DIR__ . '/schema/mysql/' . $file;
if (!is_readable($sqlFile)) {
    http_response_code(404);
    echo json_encode(['ok' => false, 'error' => 'sql_file_missing', 'file' => $file]);
    exit;
}

$sqlBytes = filesize($sqlFile);
$minBytes = match (true) {
    str_contains($file, '_seed') => 128,
    preg_match('/^001_/', $file) === 1 => 2048,
    default => 512,
};
if ($sqlBytes === false || $sqlBytes < $minBytes) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'error' => 'sql_file_too_small',
        'file' => $file,
        'bytes' => $sqlBytes === false ? 0 : $sqlBytes,
    ]);
    exit;
}

/** @var array{host:string,db:string,user:string,pass:string,port?:int} $cfg */
$cfg = require $configFile;
$mysqli = @new mysqli(
    $cfg['host'],
    $cfg['user'],
    $cfg['pass'],
    $cfg['db'],
    (int) ($cfg['port'] ?? 3306),
);
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'db_connect']);
    exit;
}

$mysqli->set_charset('utf8mb4');
$sql = (string) file_get_contents($sqlFile);
if ($mysqli->multi_query($sql)) {
    do {
        if ($result = $mysqli->store_result()) {
            $result->free();
        }
    } while ($mysqli->more_results() && $mysqli->next_result());
}

if ($mysqli->errno) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'sql_failed', 'message' => $mysqli->error]);
    exit;
}

$tables = 0;
if ($countResult = $mysqli->query("SHOW TABLES LIKE 'kakiempa_v2_%'")) {
    $tables = $countResult->num_rows;
    $countResult->free();
}

if ($tables < 2) {
    http_response_code(500);
    echo json_encode([
        'ok' => false,
        'error' => 'no_tables_created',
        'file' => $file,
        'bytes' => $sqlBytes,
        'tables_v2' => $tables,
    ]);
    exit;
}

echo json_encode([
    'ok' => true,
    'file' => $file,
    'applied' => true,
    'bytes' => $sqlBytes,
    'tables_v2' => $tables,
    'database' => $cfg['db'] ?? null,
], JSON_UNESCAPED_UNICODE);
