<?php
/**
 * Webhook deploy — picu VersionControl/update dari dalam server (localhost:2083).
 * Menghindari blokir FTP/port eksternal dan disable_functions exec().
 */
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$configFile = __DIR__ . '/.git_deploy_config.php';
$secretFile = __DIR__ . '/.git_deploy_secret';

$provided = trim((string) ($_GET['secret'] ?? $_SERVER['HTTP_X_DEPLOY_SECRET'] ?? ''));
$expected = is_readable($secretFile) ? trim((string) file_get_contents($secretFile)) : '';

if ($expected === '' || $provided === '' || !hash_equals($expected, $provided)) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'forbidden']);
    exit;
}

if (($_GET['action'] ?? '') === 'ping') {
    echo json_encode(['ok' => true, 'ping' => true, 'has_config' => is_readable($configFile)]);
    exit;
}

if (!is_readable($configFile)) {
    http_response_code(503);
    echo json_encode(['ok' => false, 'error' => 'missing_config']);
    exit;
}

/** @var array{cpanel_user:string,cpanel_pass:string,repo_path:string,cpanel_host:string} $cfg */
$cfg = require $configFile;

$branch = preg_replace('/[^a-zA-Z0-9_\\-]/', '', (string) ($_GET['branch'] ?? 'main')) ?: 'main';
$host = $cfg['cpanel_host'] ?? '127.0.0.1';
$repo = $cfg['repo_path'] ?? '/home/kakiempa/repo_kakiempat';
$user = $cfg['cpanel_user'] ?? 'kakiempa';
$pass = $cfg['cpanel_pass'] ?? '';

$query = http_build_query([
    'repository_root' => $repo,
    'branch' => $branch,
]);

$urls = [
    "https://{$host}:2083/execute/VersionControl/update?{$query}",
    'https://kakiempat.com:2083/execute/VersionControl/update?' . $query,
];

$last = null;
foreach ($urls as $url) {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_USERPWD => "{$user}:{$pass}",
        CURLOPT_HTTPHEADER => ['Accept: application/json'],
        CURLOPT_CONNECTTIMEOUT => 30,
        CURLOPT_TIMEOUT => 300,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);
    $body = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $last = ['url' => $url, 'http' => $code, 'body' => $body];
    if ($code === 200 && is_string($body) && str_contains($body, '"status":1')) {
        echo json_encode(['ok' => true, 'via' => 'VersionControl/update', 'detail' => $last]);
        exit;
    }
}

http_response_code(500);
echo json_encode(['ok' => false, 'error' => 'uapi_failed', 'detail' => $last]);
