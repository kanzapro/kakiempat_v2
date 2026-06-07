#!/usr/bin/env bash
# Upload satu file ke cPanel via Fileman/save_file_content (POST content@ benar).
set -euo pipefail

REMOTE_DIR="$1"
REMOTE_FILE="$2"
LOCAL_FILE="$3"

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "File lokal tidak ada: $LOCAL_FILE" >&2
  exit 1
fi

CPANEL_HOST="${CPANEL_HOST:-kakiempat.com}"
CPANEL_USER="${CPANEL_USER:-kakiempa}"

for attempt in $(seq 1 5); do
  if [[ -n "${CPANEL_TOKEN:-}" ]]; then
    http_code=$(curl -sS -o /tmp/cpanel_upload.json -w "%{http_code}" \
      --connect-timeout 30 --max-time 180 \
      -H "Authorization: cpanel ${CPANEL_USER}:${CPANEL_TOKEN}" \
      -H "Accept: application/json" \
      "https://${CPANEL_HOST}:2083/execute/Fileman/save_file_content" \
      --data-urlencode "dir=${REMOTE_DIR}" \
      --data-urlencode "file=${REMOTE_FILE}" \
      --data-urlencode "content@${LOCAL_FILE}" 2>/dev/null || echo "000")
  else
    http_code=$(curl -sS -o /tmp/cpanel_upload.json -w "%{http_code}" \
      --connect-timeout 30 --max-time 180 \
      -u "${CPANEL_USER}:${CPANEL_PASS}" \
      -H "Accept: application/json" \
      "https://${CPANEL_HOST}:2083/execute/Fileman/save_file_content" \
      --data-urlencode "dir=${REMOTE_DIR}" \
      --data-urlencode "file=${REMOTE_FILE}" \
      --data-urlencode "content@${LOCAL_FILE}" 2>/dev/null || echo "000")
  fi

  if [[ "$http_code" == "200" ]] && grep -q '"status":1' /tmp/cpanel_upload.json; then
    cat /tmp/cpanel_upload.json
    exit 0
  fi
  echo "Upload attempt $attempt/$5 HTTP $http_code" >&2
  cat /tmp/cpanel_upload.json >&2 || true
  sleep $((attempt * 5))
done
exit 1
