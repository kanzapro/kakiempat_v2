#!/usr/bin/env bash
# Tulis .git_deploy_secret ke api.kakiempat.com via UAPI (sekali bootstrap).
set -euo pipefail

if [[ -z "${GIT_DEPLOY_SECRET:-}" ]]; then
  echo "GIT_DEPLOY_SECRET kosong — skip bootstrap"
  exit 0
fi

SECRET_FILE="/home/kakiempa/api.kakiempat.com/.git_deploy_secret"
TMP=$(mktemp)
echo -n "$GIT_DEPLOY_SECRET" > "$TMP"
trap 'rm -f "$TMP"' EXIT

encoded_dir=$(python3 -c "import urllib.parse; print(urllib.parse.quote('/home/kakiempa/api.kakiempat.com'))")
resp=$(bash "$(dirname "$0")/cpanel_curl_retry.sh" \
  "Fileman/save_file_content?dir=${encoded_dir}&file=.git_deploy_secret&content@${TMP}" 5)
echo "$resp" | grep -q '"status":1' || { echo "Gagal tulis .git_deploy_secret: $resp" >&2; exit 1; }
echo "OK .git_deploy_secret -> $SECRET_FILE"
