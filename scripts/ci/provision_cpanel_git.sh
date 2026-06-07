#!/usr/bin/env bash
# Provision cPanel Git repo jika belum ada — dipanggil dari GitHub Actions.
set -euo pipefail

CPANEL_HOST="${CPANEL_HOST:-kakiempat.com}"
CPANEL_USER="${CPANEL_USER:-kakiempa}"
REPO_PATH="${CPANEL_REPO_PATH:-/home/kakiempa/repo_kakiempat}"
REPO_NAME="${CPANEL_REPO_NAME:-kakiempat_v2}"
GITHUB_REPO="${GITHUB_REPOSITORY:-kanzapro/kakiempat_v2}"
BRANCH="${DEPLOY_BRANCH:-main}"

if [[ -z "${CPANEL_PASS:-}" && -z "${CPANEL_TOKEN:-}" ]]; then
  echo "CPANEL_PASS atau CPANEL_TOKEN wajib diisi" >&2
  exit 1
fi

cpanel_curl() {
  local query="$1"
  local url="https://${CPANEL_HOST}:2083/execute/${query}"
  if [[ -n "${CPANEL_TOKEN:-}" ]]; then
    curl -sS -H "Authorization: cpanel ${CPANEL_USER}:${CPANEL_TOKEN}" -H "Accept: application/json" "$url"
  else
    curl -sS -u "${CPANEL_USER}:${CPANEL_PASS}" -H "Accept: application/json" "$url"
  fi
}

echo "Cek repo Git di cPanel: $REPO_PATH"
retrieve=$(cpanel_curl "VersionControl/retrieve")
if echo "$retrieve" | grep -q "\"repository_root\":\"${REPO_PATH}\""; then
  echo "Repo sudah ada: $REPO_PATH"
  exit 0
fi

if [[ -z "${REPO_CLONE_TOKEN:-}" ]]; then
  echo "REPO_CLONE_TOKEN kosong — tidak bisa clone private repo. Buat repo manual di cPanel Git." >&2
  exit 1
fi

export GITHUB_REPO
source_repo=$(python3 - <<'PY'
import json, os, urllib.parse
token = os.environ["REPO_CLONE_TOKEN"]
repo = os.environ["GITHUB_REPO"]
clone_url = f"https://x-access-token:{token}@github.com/{repo}.git"
print(urllib.parse.quote(json.dumps({"remote_name": "origin", "url": clone_url})))
PY
)

echo "Membuat repo Git: $REPO_NAME -> $REPO_PATH"
encoded_root=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$REPO_PATH'''))")
encoded_name=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$REPO_NAME'''))")
create=$(cpanel_curl "VersionControl/create?repository_root=${encoded_root}&name=${encoded_name}&type=git&source_repository=${source_repo}")

echo "$create"
if ! echo "$create" | grep -q '"status":1'; then
  echo "VersionControl/create gagal" >&2
  exit 1
fi

echo "Repo dibuat — clone berjalan di background Task Queue cPanel."
