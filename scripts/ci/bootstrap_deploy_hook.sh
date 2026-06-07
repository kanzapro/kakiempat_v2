#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${GIT_DEPLOY_SECRET:-}" || -z "${CPANEL_PASS:-}" ]]; then
  echo "GIT_DEPLOY_SECRET / CPANEL_PASS kosong — skip"
  exit 0
fi

API_DIR="/home/kakiempa/api.kakiempat.com"
REPO_PATH="${CPANEL_REPO_PATH:-/home/kakiempa/repo_kakiempat}"
CPANEL_USER="${CPANEL_USER:-kakiempa}"
UPLOAD="$(dirname "$0")/cpanel_upload_file.sh"
chmod +x "$UPLOAD"

TMP_SECRET=$(mktemp)
TMP_CONFIG=$(mktemp)
trap 'rm -f "$TMP_SECRET" "$TMP_CONFIG"' EXIT

echo -n "$GIT_DEPLOY_SECRET" > "$TMP_SECRET"
cat > "$TMP_CONFIG" <<PHP
<?php
declare(strict_types=1);

if (isset(\$_GET['deploy'])) {
    header('Content-Type: application/json; charset=utf-8');
    \$secretFile = __DIR__ . '/.git_deploy_secret';
    \$expected = is_readable(\$secretFile) ? trim((string) file_get_contents(\$secretFile)) : '';
    \$provided = trim((string) (\$_GET['secret'] ?? \$_SERVER['HTTP_X_DEPLOY_SECRET'] ?? ''));
    if (\$expected === '' || \$provided === '' || !hash_equals(\$expected, \$provided)) {
        http_response_code(403);
        echo json_encode(['ok' => false, 'error' => 'forbidden']);
        exit;
    }
    \$cfg = [
        'cpanel_user' => '${CPANEL_USER}',
        'cpanel_pass' => '${CPANEL_PASS}',
        'repo_path' => '${REPO_PATH}',
        'cpanel_host' => '127.0.0.1',
    ];
    \$repo = \$cfg['repo_path'];
    \$branch = preg_replace('/[^a-zA-Z0-9_\\\\-]/', '', (string) (\$_GET['branch'] ?? 'main')) ?: 'main';
    \$auth = (\$cfg['cpanel_user'] ?? 'kakiempa') . ':' . (\$cfg['cpanel_pass'] ?? '');
    \$pullUrl = 'https://127.0.0.1:2083/execute/VersionControl/update?' . http_build_query(['repository_root' => \$repo, 'branch' => \$branch]);
    \$depUrl = 'https://127.0.0.1:2083/execute/VersionControlDeployment/create?' . http_build_query(['repository_root' => \$repo]);
    \$pull = ['http' => 0, 'body' => ''];
    \$deploy = ['http' => 0, 'body' => ''];
    foreach ([[\$pullUrl, &\$pull], [\$depUrl, &\$deploy]] as \$job) {
        \$ch = curl_init(\$job[0]);
        curl_setopt_array(\$ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_USERPWD => \$auth, CURLOPT_TIMEOUT => 300, CURLOPT_SSL_VERIFYPEER => false]);
        \$job[1]['body'] = (string) curl_exec(\$ch);
        \$job[1]['http'] = (int) curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
        curl_close(\$ch);
    }
    \$ok = \$pull['http'] === 200 && str_contains(\$pull['body'], '"status":1')
        && \$deploy['http'] === 200 && str_contains(\$deploy['body'], '"status":1');
    http_response_code(\$ok ? 200 : 500);
    echo json_encode(['ok' => \$ok, 'pull' => \$pull, 'deploy' => \$deploy]);
    exit;
}

return [
    'cpanel_user' => '${CPANEL_USER}',
    'cpanel_pass' => '${CPANEL_PASS}',
    'repo_path' => '${REPO_PATH}',
    'cpanel_host' => '127.0.0.1',
];
PHP

export CPANEL_PASS CPANEL_TOKEN
"$UPLOAD" "$API_DIR" ".git_deploy_secret" "$TMP_SECRET"
"$UPLOAD" "$API_DIR" ".git_deploy_config.php" "$TMP_CONFIG"
echo "Bootstrap deploy config OK"
