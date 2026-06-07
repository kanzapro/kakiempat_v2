#!/usr/bin/env bash
# Deploy artefak build ke docroot cPanel — dipanggil dari .cpanel.yml setelah git pull.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

HOME_CP="${CPANEL_HOME:-/home/kakiempa}"

echo "=== cPanel deploy: $ROOT -> $HOME_CP ==="

# API: paket dari hosting/ jika artefak belum ada di repo
if [[ ! -d "$ROOT/build/deploy_api" ]]; then
  echo "build/deploy_api tidak ada — menjalankan prepare_api_package.sh"
  bash "$ROOT/scripts/ci/prepare_api_package.sh"
fi

rsync -a --delete \
  --exclude '.mysql_v2.php' \
  --exclude '.migrate_v2_secret' \
  --exclude '.agent_telemetry_secret' \
  --exclude '.payment_webhook_secret' \
  --exclude '.payment_config.php' \
  --exclude '.notifications_path.php' \
  --exclude 'uploads/' \
  --exclude 'backups/' \
  "$ROOT/build/deploy_api/" "$HOME_CP/api.kakiempat.com/"
echo "OK api -> api.kakiempat.com/"

# Owner BFF parsial — overlay tanpa --delete (menang atas deploy_api stale)
if [[ -d "$ROOT/build/deploy_api_owner" ]]; then
  rsync -a "$ROOT/build/deploy_api_owner/" "$HOME_CP/api.kakiempat.com/"
  echo "OK api owner overlay -> api.kakiempat.com/ (owner_v2.php + lib)"
fi

declare -A WEB_DOCROOTS=(
  [www]=public_html
  [owner]=owner.kakiempat.com
  [sitter]=sitter.kakiempat.com
  [admin]=admin.kakiempat.com
  [staging]=staging.kakiempat.com
)

for target in www owner sitter admin staging; do
  src="$ROOT/build/deploy/$target/web"
  if [[ ! -d "$src" ]]; then
    echo "SKIP web/$target — $src tidak ada (build lokal belum di-commit?)"
    continue
  fi
  dest="$HOME_CP/${WEB_DOCROOTS[$target]}/"
  rsync -a --delete "$src/" "$dest"
  echo "OK $target -> ${WEB_DOCROOTS[$target]}/"
  if [[ "$target" == "www" ]]; then
    www_sub="$HOME_CP/www.kakiempat.com/"
    rsync -a --delete "$src/" "$www_sub"
    echo "OK www -> www.kakiempat.com/"
  fi
done

echo "=== cPanel deploy selesai ==="
