<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
$s = trim((string) @file_get_contents(__DIR__ . '/.git_deploy_secret') ?: '');
$p = trim((string) ($_GET['secret'] ?? $_SERVER['HTTP_X_DEPLOY_SECRET'] ?? ''));
if ($s === '' || $p === '' || !hash_equals($s, $p)) {
    http_response_code(403);
    echo '{"ok":false,"error":"forbidden"}';
    exit;
}
if (!is_readable(__DIR__ . '/.git_deploy_config.php')) {
    http_response_code(503);
    echo '{"ok":false,"error":"missing_config"}';
    exit;
}
$c = require __DIR__ . '/.git_deploy_config.php';
$b = preg_replace('/[^a-zA-Z0-9_\\-]/', '', (string) ($_GET['branch'] ?? 'main')) ?: 'main';
$q = http_build_query([
    'repository_root' => $c['repo_path'] ?? '/home/kakiempa/repo_kakiempat',
    'branch' => $b,
]);
$ch = curl_init('https://127.0.0.1:2083/execute/VersionControl/update?' . $q);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_USERPWD => ($c['cpanel_user'] ?? 'kakiempa') . ':' . ($c['cpanel_pass'] ?? ''),
    CURLOPT_TIMEOUT => 300,
    CURLOPT_SSL_VERIFYPEER => false,
]);
$body = curl_exec($ch);
$h = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);
$ok = $h === 200 && is_string($body) && str_contains($body, '"status":1');
http_response_code($ok ? 200 : 500);
echo json_encode(['ok' => $ok, 'http' => $h, 'body' => $body]);
