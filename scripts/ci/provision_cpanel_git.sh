#!/usr/bin/env bash
# Provision cPanel Git repo (idempotent). Clone HTTPS tanpa password (repo public).
set -euo pipefail

CPANEL_HOST="${CPANEL_HOST:-kakiempat.com}"
CPANEL_USER="${CPANEL_USER:-kakiempa}"
REPO_PATH="${CPANEL_REPO_PATH:-/home/kakiempa/repo_kakiempat}"
REPO_NAME="${CPANEL_REPO_NAME:-kakiempat_v2}"
GITHUB_REPO="${GITHUB_REPOSITORY:-kanzapro/kakiempat_v2}"

if [[ -z "${CPANEL_PASS:-}" && -z "${CPANEL_TOKEN:-}" ]]; then
  echo "CPANEL_PASS atau CPANEL_TOKEN wajib diisi" >&2
  exit 1
fi

cpanel_curl() {
  bash "$(dirname "$0")/cpanel_curl_retry.sh" "$1" 5
}

echo "Cek repo Git di cPanel: $REPO_PATH"
retrieve=$(cpanel_curl "VersionControl/retrieve")
if echo "$retrieve" | grep -q "\"repository_root\":\"${REPO_PATH}\""; then
  echo "Repo sudah ada: $REPO_PATH"
  exit 0
fi

clone_url="https://github.com/${GITHUB_REPO}.git"
source_repo=$(CLONE_URL="$clone_url" python3 - <<'PY'
import json, os, urllib.parse
print(urllib.parse.quote(json.dumps({"remote_name": "origin", "url": os.environ["CLONE_URL"]})))
PY
)

encoded_root=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$REPO_PATH'''))")
encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$REPO_NAME'''))")

echo "Membuat repo Git: $REPO_NAME -> $REPO_PATH"
create=$(cpanel_curl "VersionControl/create?repository_root=${encoded_root}&name=${encoded_name}&type=git&source_repository=${source_repo}")
echo "$create"

if ! echo "$create" | grep -q '"status":1'; then
  echo "VersionControl/create gagal" >&2
  exit 1
fi

echo "Clone awal berjalan di Task Queue cPanel — tunggu..."
sleep 25
