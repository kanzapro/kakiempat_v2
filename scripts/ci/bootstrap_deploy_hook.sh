#!/usr/bin/env bash
# Tulis .git_deploy_secret + .git_deploy_config.php ke api.kakiempat.com via UAPI.
set -euo pipefail

if [[ -z "${GIT_DEPLOY_SECRET:-}" ]]; then
  echo "GIT_DEPLOY_SECRET kosong — skip bootstrap"
  exit 0
fi
if [[ -z "${CPANEL_PASS:-}" ]]; then
  echo "CPANEL_PASS kosong — skip bootstrap"
  exit 0
fi

API_DIR="/home/kakiempa/api.kakiempat.com"
REPO_PATH="${CPANEL_REPO_PATH:-/home/kakiempa/repo_kakiempat}"
CPANEL_USER="${CPANEL_USER:-kakiempa}"

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

encoded_dir=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${API_DIR}'))")

for pair in ".git_deploy_secret@${TMP_SECRET}" ".git_deploy_config.php@${TMP_CONFIG}"; do
  file="${pair%%@*}"
  path="${pair#*@}"
  resp=$(bash "$(dirname "$0")/cpanel_curl_retry.sh" \
    "Fileman/save_file_content?dir=${encoded_dir}&file=${file}&content@${path}" 5)
  echo "$resp" | grep -q '"status":1' || { echo "Gagal tulis $file: $resp" >&2; exit 1; }
  echo "OK $file"
done
