#!/usr/bin/env bash
# Paket API v2 untuk CI — mirror scripts/deploy_api.ps1 (tanpa rahasia server).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/hosting/api.kakiempat.com"
DEST="$ROOT/build/deploy_api"

if [[ ! -d "$SRC" ]]; then
  echo "Missing $SRC" >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"

items=(
  auth_v2.php user_v2.php owner_v2.php pet_v2.php sitter_v2.php
  service_v2.php booking_v2.php marketplace_v2.php chat_v2.php notification_v2.php
  review_v2.php admin_v2.php partner_v2.php community_v2.php business_v2.php
  cors.php v2_api_common.php index.php
  apply_v2_migration.php health.php wallet_v2.php
  payment_v2.php payment_webhook.php payment_status.php
  get_notifications.php get_unread_notifications.php backup_db_v2.php
  .htaccess robots.txt
  lib schema data backups uploads
)

for name in "${items[@]}"; do
  if [[ ! -e "$SRC/$name" ]]; then
    echo "Missing $SRC/$name" >&2
    exit 1
  fi
  cp -a "$SRC/$name" "$DEST/"
done

sql="$DEST/schema/mysql/001_core_tables.sql"
if [[ ! -f "$sql" ]]; then
  echo "Missing $sql" >&2
  exit 1
fi
bytes=$(wc -c < "$sql" | tr -d ' ')
if (( bytes < 2048 )); then
  echo "001_core_tables.sql terlalu kecil ($bytes bytes)" >&2
  exit 1
fi

echo "Paket API siap: $DEST ($bytes bytes SQL)"
