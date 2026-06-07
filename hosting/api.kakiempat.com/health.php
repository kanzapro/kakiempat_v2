<?php
declare(strict_types=1);

/**
 * Health check + deploy trigger (localhost UAPI).
 * GET /health.php → status DB
 * GET /health.php?action=deploy&secret=... → git pull + .cpanel.yml
 */
require_once __DIR__ . '/v2_api_common.php';

header('Content-Type: application/json; charset=utf-8');

if (($_GET['action'] ?? '') === 'deploy') {
    $secretFile = __DIR__ . '/.git_deploy_secret';
    $configFile = __DIR__ . '/.git_deploy_config.php';
    $expected = is_readable($secretFile) ? trim((string) file_get_contents($secretFile)) : '';
    $provided = trim((string) ($_GET['secret'] ?? $_SERVER['HTTP_X_DEPLOY_SECRET'] ?? ''));
    if ($expected === '' || $provided === '' || !hash_equals($expected, $provided)) {
        http_response_code(403);
        echo json_encode(['ok' => false, 'error' => 'forbidden']);
        exit;
    }
    if (!is_readable($configFile)) {
        http_response_code(503);
        echo json_encode(['ok' => false, 'error' => 'missing_config']);
        exit;
    }
    $cfg = require $configFile;
    $branch = preg_replace('/[^a-zA-Z0-9_\\-]/', '', (string) ($_GET['branch'] ?? 'main')) ?: 'main';
    $query = http_build_query([
        'repository_root' => $cfg['repo_path'] ?? '/home/kakiempa/repo_kakiempat',
        'branch' => $branch,
    ]);
    $url = 'https://127.0.0.1:2083/execute/VersionControl/update?' . $query;
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_USERPWD => ($cfg['cpanel_user'] ?? 'kakiempa') . ':' . ($cfg['cpanel_pass'] ?? ''),
        CURLOPT_HTTPHEADER => ['Accept: application/json'],
        CURLOPT_CONNECTTIMEOUT => 30,
        CURLOPT_TIMEOUT => 300,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);
    $body = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $ok = $code === 200 && is_string($body) && str_contains($body, '"status":1');
    http_response_code($ok ? 200 : 500);
    echo json_encode(['ok' => $ok, 'http' => $code, 'body' => $body]);
    exit;
}

$mysqlOk = false;
$poolMetrics = [];
try {
    $pdo = v2ApiPdo();
    $pdo->query('SELECT 1');
    $mysqlOk = true;
    $poolMetrics = v2ApiMysqlPoolMetrics($pdo);
} catch (Throwable) {
    $mysqlOk = false;
}

http_response_code($mysqlOk ? 200 : 503);
echo json_encode([
    'ok' => $mysqlOk,
    'service' => 'kakiempat_v2_api',
    'version' => '0.2.2',
    'mysql_ok' => $mysqlOk,
    'mysql_pool' => $poolMetrics,
    'ts' => date('c'),
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
