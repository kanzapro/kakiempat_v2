#!/usr/bin/env bash
# curl ke cPanel UAPI dengan retry (Imunify360 kadang blokir IP runner sementara).
set -euo pipefail

CPANEL_HOST="${CPANEL_HOST:-kakiempat.com}"
CPANEL_USER="${CPANEL_USER:-kakiempa}"
QUERY="$1"
MAX="${2:-5}"

for attempt in $(seq 1 "$MAX"); do
  url="https://${CPANEL_HOST}:2083/execute/${QUERY}"
  if [[ -n "${CPANEL_TOKEN:-}" ]]; then
    http_code=$(curl -sS -o /tmp/cpanel_api.json -w "%{http_code}" \
      --connect-timeout 30 --max-time 120 \
      -H "Authorization: cpanel ${CPANEL_USER}:${CPANEL_TOKEN}" \
      -H "Accept: application/json" \
      "$url" 2>/dev/null || echo "000")
  else
    http_code=$(curl -sS -o /tmp/cpanel_api.json -w "%{http_code}" \
      --connect-timeout 30 --max-time 120 \
      -u "${CPANEL_USER}:${CPANEL_PASS}" \
      -H "Accept: application/json" \
      "$url" 2>/dev/null || echo "000")
  fi

  if [[ "$http_code" == "200" ]]; then
    cat /tmp/cpanel_api.json
    exit 0
  fi

  echo "cPanel API attempt $attempt/$MAX failed HTTP $http_code" >&2
  sleep $((attempt * 8))
done

echo "cPanel API gagal setelah $MAX percobaan" >&2
exit 1
