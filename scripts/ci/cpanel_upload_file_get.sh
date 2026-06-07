#!/usr/bin/env bash
# Upload file kecil via UAPI GET (hindari POST timeout Imunify360).
set -euo pipefail

REMOTE_DIR="$1"
REMOTE_FILE="$2"
LOCAL_FILE="$3"

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "File lokal tidak ada: $LOCAL_FILE" >&2
  exit 1
fi

bytes=$(wc -c < "$LOCAL_FILE" | tr -d ' ')
if (( bytes > 6000 )); then
  echo "File terlalu besar untuk GET upload ($bytes bytes)" >&2
  exit 1
fi

ENC_DIR=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$REMOTE_DIR'''))")
ENC_CONTENT=$(python3 -c "import urllib.parse; print(urllib.parse.quote(open('''$LOCAL_FILE''').read()))")

bash "$(dirname "$0")/cpanel_curl_retry.sh" \
  "Fileman/save_file_content?dir=${ENC_DIR}&file=${REMOTE_FILE}&content=${ENC_CONTENT}" 6
