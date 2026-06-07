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
