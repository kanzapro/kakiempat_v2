<?php
/**
 * Webhook deploy internal — git pull + cpanel_deploy.sh dari dalam server (port 443).
 * Secret: .git_deploy_secret di docroot API (ditulis via bootstrap_deploy_hook.sh).
 */
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');

$repo = '/home/kakiempa/repo_kakiempat';
$branch = preg_replace('/[^a-zA-Z0-9_\\-]/', '', (string) ($_GET['branch'] ?? 'main')) ?: 'main';
$cloneUrl = 'https://github.com/kanzapro/kakiempat_v2.git';

$secretFile = __DIR__ . '/.git_deploy_secret';
$expected = is_readable($secretFile) ? trim((string) file_get_contents($secretFile)) : '';
$provided = trim((string) ($_GET['secret'] ?? $_SERVER['HTTP_X_DEPLOY_SECRET'] ?? ''));

if ($expected === '' || $provided === '' || !hash_equals($expected, $provided)) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'forbidden', 'has_secret_file' => $expected !== '']);
    exit;
}

$log = [];
$run = static function (string $cmd) use (&$log): int {
    $out = [];
    exec($cmd . ' 2>&1', $out, $code);
    $log[] = ['cmd' => $cmd, 'code' => $code, 'out' => implode("\n", $out)];
    return $code;
};

if (!is_dir($repo)) {
    mkdir($repo, 0755, true);
}

if (!is_dir($repo . '/.git')) {
    $code = $run('git clone --branch ' . escapeshellarg($branch) . ' --depth 1 ' . escapeshellarg($cloneUrl) . ' ' . escapeshellarg($repo));
    if ($code !== 0) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'error' => 'clone_failed', 'log' => $log]);
        exit;
    }
}

foreach ([
    'cd ' . escapeshellarg($repo) . ' && git fetch origin ' . escapeshellarg($branch),
    'cd ' . escapeshellarg($repo) . ' && git checkout ' . escapeshellarg($branch),
    'cd ' . escapeshellarg($repo) . ' && git pull origin ' . escapeshellarg($branch),
] as $cmd) {
    if ($run($cmd) !== 0) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'error' => 'git_failed', 'log' => $log]);
        exit;
    }
}

$deployScript = $repo . '/scripts/ci/cpanel_deploy.sh';
if (is_file($deployScript)) {
    if ($run('bash ' . escapeshellarg($deployScript)) !== 0) {
        http_response_code(500);
        echo json_encode(['ok' => false, 'error' => 'deploy_failed', 'log' => $log]);
        exit;
    }
} else {
    $log[] = ['cmd' => 'skip', 'code' => 0, 'out' => 'cpanel_deploy.sh belum ada — pull saja'];
}

echo json_encode(['ok' => true, 'branch' => $branch, 'log' => $log]);
