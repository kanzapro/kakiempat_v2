#!/usr/bin/env bash
# Kaki Empat v2 - helper koneksi ADB ke perangkat vivo V30 (model V2318).
#
# Pakai:
#   ./scripts/adb_connect_v2318.sh                       # deteksi device V2318 (USB / wireless yg sudah connect)
#   ./scripts/adb_connect_v2318.sh -i 192.168.1.20       # USB dulu (adb tcpip 5555) lalu connect wireless
#   ./scripts/adb_connect_v2318.sh -p 192.168.1.20:41234 -c 123456   # pairing Android 11+ (Wireless debugging)
#   ./scripts/adb_connect_v2318.sh -f                    # setelah connect, jalankan `flutter run` di repo ini
set -euo pipefail

MODEL="${ADB_MODEL:-V2318}"
PORT="${ADB_PORT:-5555}"
IP=""
PAIR_ADDR=""
PAIR_CODE=""
FLUTTER_RUN=0
SERIAL=""

usage() {
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
}

while getopts ":i:p:c:s:fh" opt; do
    case "$opt" in
        i) IP="$OPTARG" ;;
        p) PAIR_ADDR="$OPTARG" ;;
        c) PAIR_CODE="$OPTARG" ;;
        s) SERIAL="$OPTARG" ;;
        f) FLUTTER_RUN=1 ;;
        h) usage; exit 0 ;;
        \?) echo "Opsi tidak dikenal: -$OPTARG" >&2; usage; exit 2 ;;
        :)  echo "Opsi -$OPTARG butuh nilai" >&2; usage; exit 2 ;;
    esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find_adb() {
    if command -v adb >/dev/null 2>&1; then command -v adb; return 0; fi
    local candidates=(
        "${ANDROID_HOME:-}/platform-tools/adb"
        "${ANDROID_SDK_ROOT:-}/platform-tools/adb"
        "$HOME/Android/Sdk/platform-tools/adb"
        "$HOME/Library/Android/sdk/platform-tools/adb"
        "/usr/lib/android-sdk/platform-tools/adb"
        "/opt/android-sdk/platform-tools/adb"
    )
    local c
    for c in "${candidates[@]}"; do
        [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return 0; }
    done
    return 1
}

if ! ADB="$(find_adb)"; then
    cat >&2 <<'EOF'
[!] adb tidak ditemukan.

Linux/macOS:
  - Android Studio -> SDK Manager -> SDK Tools -> "Android SDK Platform-Tools"
  - atau: sudo apt install android-tools-adb   (Debian/Ubuntu)
  - atau: brew install android-platform-tools  (macOS)
  - atau unduh: https://developer.android.com/tools/releases/platform-tools
Setelah itu pastikan folder platform-tools ada di PATH atau set ANDROID_HOME.
EOF
    exit 1
fi

echo "=== ADB -> vivo V30 (model $MODEL) ==="
echo "adb: $ADB"
"$ADB" version | head -2
"$ADB" start-server >/dev/null

list_devices() { "$ADB" devices -l | sed '1d' | sed '/^[[:space:]]*$/d'; }

# --- 0. Pairing wireless (Android 11+) ---
if [ -n "$PAIR_ADDR" ] && [ -n "$PAIR_CODE" ]; then
    echo "[*] Pairing ke $PAIR_ADDR ..."
    "$ADB" pair "$PAIR_ADDR" "$PAIR_CODE"
    if [ -n "$IP" ]; then
        echo "[*] adb connect $IP:$PORT"
        "$ADB" connect "$IP:$PORT" || true
    fi
fi

# --- 1. Cari target V2318 ---
target="$SERIAL"
if [ -z "$target" ]; then
    target="$("$ADB" devices -l | awk -v m="$MODEL" 'toupper($0) ~ toupper(m) {print $1; exit}')"
fi
if [ -z "$target" ]; then
    # fallback: satu-satunya device fisik yang terhubung
    target="$(list_devices | awk '{print $1}' | grep -v '^emulator-' | head -1 || true)"
fi

if [ -z "$target" ]; then
    cat <<'EOF'
[!] Tidak ada perangkat yang terdeteksi.

Checklist di HP (vivo V30 / V2318):
  1. Pengaturan -> Tentang ponsel -> ketuk "Nomor versi" 7x (aktifkan Opsi Pengembang)
  2. Opsi Pengembang -> aktifkan "USB debugging" (+ "Install via USB" bila ada)
  3. Colok kabel USB -> pilih mode "File Transfer / MTP"
  4. Terima dialog "Allow USB debugging?" (centang Always allow)
  5. Android 11+: aktifkan juga "Wireless debugging" untuk mode nirkabel
  6. Windows: install vivo USB driver bila device tidak muncul di adb devices

Lalu jalankan ulang:
  adb devices -l
  ./scripts/adb_connect_v2318.sh -i <IP_HP>
EOF
    exit 1
fi

echo "[+] Device terdeteksi: $target"
echo "    model   : $("$ADB" -s "$target" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
echo "    android : $("$ADB" -s "$target" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
echo "    serial  : $("$ADB" -s "$target" get-serialno 2>/dev/null | tr -d '\r')"
"$ADB" devices -l | sed -n '1,20p'

# --- 2. Aktifkan TCP/IP + connect wireless (butuh device sudah terhubung USB) ---
if [ -n "$IP" ]; then
    case "$target" in
        *:*)
            echo "[=] Sudah berupa endpoint wireless: $target"
            ;;
        *)
            echo "[*] Mengaktifkan adb tcpip $PORT pada $target ..."
            "$ADB" -s "$target" tcpip "$PORT"
            sleep 2
            echo "[*] adb connect $IP:$PORT"
            "$ADB" connect "$IP:$PORT"
            ;;
    esac
    "$ADB" devices -l | sed -n '1,20p'
    target="$IP:$PORT"
fi

# --- 3. Opsional: jalankan aplikasi Flutter di device ---
if [ "$FLUTTER_RUN" -eq 1 ]; then
    if command -v flutter >/dev/null 2>&1; then
        echo "[*] flutter run -d $target (di $ROOT)"
        cd "$ROOT"
        exec flutter run -d "$target"
    fi
    echo "[!] flutter tidak ada di PATH - lewati flutter run." >&2
fi

echo "[OK] Siap. Contoh: $ADB -s $target shell getprop ro.product.model"
