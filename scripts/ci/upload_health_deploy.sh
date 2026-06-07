#!/usr/bin/env bash
# Upload health.php via UAPI GET (file kecil).
set -euo pipefail
LOCAL="${1:-hosting/api.kakiempat.com/health.php}"
DIR="/home/kakiempa/api.kakiempat.com"
CONTENT=$(python3 -c "import urllib.parse; print(urllib.parse.quote(open('${LOCAL}').read()))")
ENC_DIR=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${DIR}'))")
bash "$(dirname "$0")/cpanel_curl_retry.sh" \
  "Fileman/save_file_content?dir=${ENC_DIR}&file=health.php&content=${CONTENT}" 8
