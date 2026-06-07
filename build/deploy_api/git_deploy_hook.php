<?php
/**
 * Webhook deploy internal — git pull + .cpanel.yml dari dalam server (port 443).
 * Dipanggil GitHub Actions; tidak butuh FTP atau port 2083 eksternal.
 *
 * Secret: file .git_deploy_secret di docroot API (jangan commit).
 */
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$secretFile = __DIR__ . '/.git_deploy_secret';
$expected = is_readable($secretFile) ? trim((string) file_get_contents($secretFile)) : '';
$provided = (string) ($_GET['secret'] ?? $_SERVER['HTTP_X_DEPLOY_SECRET'] ?? '');

if ($expected === '' || !hash_equals($expected, $provided)) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'forbidden']);
    exit;
}

$repo = '/home/kakiempa/repo_kakiempat';
$branch = preg_replace('/[^a-zA-Z0-9_\\-\\/]/', '', (string) ($_GET['branch'] ?? 'main')) ?: 'main';
$deployScript = $repo . '/scripts/ci/cpanel_deploy.sh';
$log = [];

if (!is_dir($repo . '/.git')) {
    http_response_code(503);
    echo json_encode(['ok' => false, 'error' => 'repo_not_ready', 'path' => $repo]);
    exit;
}

$cmds = [
    "cd " . escapeshellarg($repo) . " && git fetch origin " . escapeshellarg($branch) . " 2>&1",
    "cd " . escapeshellarg($repo) . " && git checkout " . escapeshellarg($branch) . " 2>&1",
    "cd " . escapeshellarg($repo) . " && git pull origin " . escapeshellarg($branch) . " 2>&1",
];

foreach ($cmds as $cmd) {
    $out = [];
    exec($cmd, $out, $code);
    $log[] = ['cmd' => $cmd, 'code' => $code, 'out' => implode("\n", $out)];
    if ($code !== 0) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'error' => 'git_failed', 'log' => $log]);
        exit;
    }
}

if (is_executable($deployScript)) {
    $out = [];
    exec('bash ' . escapeshellarg($deployScript) . ' 2>&1', $out, $code);
    $log[] = ['cmd' => 'cpanel_deploy.sh', 'code' => $code, 'out' => implode("\n", $out)];
    if ($code !== 0) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'error' => 'deploy_failed', 'log' => $log]);
        exit;
    }
}

echo json_encode(['ok' => true, 'branch' => $branch, 'log' => $log]);
