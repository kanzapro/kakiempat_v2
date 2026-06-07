#!/usr/bin/env bash
# Paket Flutter web per subdomain — mirror scripts/lib/web_seo.ps1 + deploy_web.ps1.
set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <owner|sitter|admin|staging|www>" >&2
  exit 1
fi

case "$TARGET" in
  owner|sitter|admin|staging|www) ;;
  *)
    echo "Target tidak dikenal: $TARGET" >&2
    exit 1
    ;;
esac

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_SRC="$ROOT/build/web"
SHARED="$ROOT/hosting/web_shared"
DEST="$ROOT/build/deploy/$TARGET/web"

if [[ ! -d "$WEB_SRC" ]]; then
  echo "Build web belum ada: $WEB_SRC — jalankan flutter build web dulu." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "$WEB_SRC/." "$DEST/"

if [[ -f "$SHARED/.htaccess" ]]; then
  cp "$SHARED/.htaccess" "$DEST/.htaccess"
fi

if [[ "$TARGET" == "www" ]]; then
  cp "$SHARED/robots-www.txt" "$DEST/robots.txt"
  cp "$SHARED/sitemap.xml" "$DEST/sitemap.xml"
else
  cp "$SHARED/robots-noindex.txt" "$DEST/robots.txt"
  rm -f "$DEST/sitemap.xml"

  index="$DEST/index.html"
  if [[ -f "$index" ]]; then
    if ! grep -q 'name="robots"' "$index"; then
      sed -i 's|<meta charset="UTF-8">|<meta charset="UTF-8">\n  <meta name="robots" content="noindex, nofollow">|' "$index"
    fi
    case "$TARGET" in
      owner)   title='Kaki Empat - Pemilik Hewan' ;;
      sitter)  title='Kaki Empat - Pengasuh Hewan' ;;
      admin)   title='Kaki Empat - Panel Admin' ;;
      staging) title='Kaki Empat - Staging' ;;
    esac
    sed -i "s|<title>[^<]*</title>|<title>$title</title>|" "$index"
  fi
fi

# html renderer: hapus canvaskit lokal (CDN saat runtime).
if [[ -d "$DEST/canvaskit" ]]; then
  rm -rf "$DEST/canvaskit"
fi

echo "Paket web siap: $DEST (target=$TARGET)"
