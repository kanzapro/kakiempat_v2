# Kaki Empat v2 - helper koneksi ADB ke perangkat vivo V30 (model V2318).
#
# Pakai:
#   .\scripts\adb_connect_v2318.ps1                          # deteksi device V2318 (USB / wireless yg sudah connect)
#   .\scripts\adb_connect_v2318.ps1 -Ip 192.168.1.20         # USB dulu (adb tcpip 5555) lalu connect wireless
#   .\scripts\adb_connect_v2318.ps1 -PairAddress 192.168.1.20:41234 -PairCode 123456   # pairing Android 11+
#   .\scripts\adb_connect_v2318.ps1 -FlutterRun              # setelah connect, jalankan flutter run di repo ini
param(
    [string]$Model = 'V2318',
    [int]$Port = 5555,
    [string]$Ip,
    [string]$PairAddress,
    [string]$PairCode,
    [string]$Serial,
    [switch]$FlutterRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Get-AdbPath {
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $roots = @(
        $env:ANDROID_HOME,
        $env:ANDROID_SDK_ROOT,
        (Join-Path $env:LOCALAPPDATA 'Android\Sdk'),
        'C:\platform-tools'
    ) | Where-Object { $_ }
    foreach ($r in $roots) {
        $candidate = Join-Path $r 'platform-tools\adb.exe'
        if (Test-Path $candidate) { return $candidate }
    }
    throw "adb tidak ditemukan. Install 'Android SDK Platform-Tools' via SDK Manager, atau set ANDROID_HOME, atau unduh https://developer.android.com/tools/releases/platform-tools"
}

$adb = Get-AdbPath
Write-Host "=== ADB -> vivo V30 (model $Model) ===" -ForegroundColor Cyan
Write-Host "adb: $adb"
& $adb version | Select-Object -First 2
& $adb start-server | Out-Null

function Get-DeviceList {
    & $adb devices -l | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
}

# --- 0. Pairing wireless (Android 11+) ---
if ($PairAddress -and $PairCode) {
    Write-Host "[*] Pairing ke $PairAddress ..." -ForegroundColor Yellow
    & $adb pair $PairAddress $PairCode
    if ($Ip) {
        Write-Host "[*] adb connect ${Ip}:$Port" -ForegroundColor Yellow
        & $adb connect "${Ip}:$Port"
    }
}

# --- 1. Cari target V2318 ---
$target = $Serial
if (-not $target) {
    $target = (Get-DeviceList | Where-Object { $_ -match [regex]::Escape($Model) } | Select-Object -First 1) -split '\s+' | Select-Object -First 1
}
if (-not $target) {
    $target = (Get-DeviceList | Where-Object { $_ -notmatch '^emulator-' } | Select-Object -First 1) -split '\s+' | Select-Object -First 1
}

if (-not $target) {
    Write-Host '[!] Tidak ada perangkat yang terdeteksi.' -ForegroundColor Red
    Write-Host @'
Checklist di HP (vivo V30 / V2318):
  1. Pengaturan -> Tentang ponsel -> ketuk "Nomor versi" 7x (aktifkan Opsi Pengembang)
  2. Opsi Pengembang -> aktifkan "USB debugging" (+ "Install via USB" bila ada)
  3. Colok kabel USB -> pilih mode "File Transfer / MTP"
  4. Terima dialog "Allow USB debugging?" (centang Always allow)
  5. Android 11+: aktifkan juga "Wireless debugging" untuk mode nirkabel
  6. Windows: install vivo USB driver bila device tidak muncul di adb devices

Lalu jalankan ulang:
  adb devices -l
  .\scripts\adb_connect_v2318.ps1 -Ip <IP_HP>
'@ -ForegroundColor Yellow
    exit 1
}

$devModel = (& $adb -s $target shell getprop ro.product.model) -join ''
$devRelease = (& $adb -s $target shell getprop ro.build.version.release) -join ''
$devSerial = (& $adb -s $target get-serialno) -join ''
Write-Host "[+] Device terdeteksi: $target" -ForegroundColor Green
Write-Host "    model   : $devModel"
Write-Host "    android : $devRelease"
Write-Host "    serial  : $devSerial"
& $adb devices -l

# --- 2. Aktifkan TCP/IP + connect wireless (butuh device sudah terhubung USB) ---
if ($Ip) {
    if ($target -match ':') {
        Write-Host "[=] Sudah berupa endpoint wireless: $target"
    } else {
        Write-Host "[*] Mengaktifkan adb tcpip $Port pada $target ..." -ForegroundColor Yellow
        & $adb -s $target tcpip $Port
        Start-Sleep -Seconds 2
        Write-Host "[*] adb connect ${Ip}:$Port" -ForegroundColor Yellow
        & $adb connect "${Ip}:$Port"
    }
    & $adb devices -l
    $target = "${Ip}:$Port"
}

# --- 3. Opsional: jalankan aplikasi Flutter di device ---
if ($FlutterRun) {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Write-Host "[*] flutter run -d $target (di $root)" -ForegroundColor Cyan
        Set-Location $root
        & flutter run -d $target
        exit $LASTEXITCODE
    }
    Write-Warning 'flutter tidak ada di PATH - lewati flutter run.'
}

Write-Host "[OK] Siap. Contoh: adb -s $target shell getprop ro.product.model" -ForegroundColor Green
