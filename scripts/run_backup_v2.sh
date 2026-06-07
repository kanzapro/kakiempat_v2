#!/usr/bin/env bash
# Jalankan backup database v2 via HTTP (manual / CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_BASE="${API_BASE:-https://api.kakiempat.com}"
SECRET=""

if [[ -f "${ROOT}/.env" ]]; then
  SECRET="$(grep -E '^V2_MIGRATE_SECRET=' "${ROOT}/.env" | head -n1 | cut -d= -f2- | tr -d "\"'" || true)"
fi

if [[ -z "${SECRET}" && -f "${ROOT}/.cursor/secrets/hosting.credentials" ]]; then
  SECRET="$(awk -F= '
    /^\[api_deploy\]$/ { in_section=1; next }
    /^\[/ { in_section=0 }
    in_section && $1=="migrate_secret" { print $2; exit }
  ' "${ROOT}/.cursor/secrets/hosting.credentials")"
fi

if [[ -z "${SECRET}" ]]; then
  echo "Secret backup tidak ditemukan (.env V2_MIGRATE_SECRET atau hosting.credentials)." >&2
  exit 1
fi

ENC_SECRET="$(python3 -c "import urllib.parse; print(urllib.parse.quote('${SECRET}'))" 2>/dev/null || php -r "echo rawurlencode(getenv('SECRET') ?: '');" SECRET="${SECRET}")"
URL="${API_BASE}/backup_db_v2.php?key=${ENC_SECRET}"

echo "Backup v2: ${API_BASE} ..."
curl -sS -A 'Mozilla/5.0' -H 'Accept: application/json' "${URL}"
echo
