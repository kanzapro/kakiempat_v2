# Kaki Empat v2 - expose perangkat vivo V30 (model V2318) ke jaringan supaya agen
# (Cline di sandbox cloud) bisa `adb connect` ke HP ini.
#
# Pakai:
#   .\scripts\adb_expose_v2318.ps1                       # adb tcpip + info IP LAN saja
#   .\scripts\adb_expose_v2318.ps1 -Tunnel ngrok         # + tunnel ngrok tcp (publik)
#   .\scripts\adb_expose_v2318.ps1 -Tunnel tailscale     # + tailscale funnel raw TCP (port 10000)
#   .\scripts\adb_expose_v2318.ps1 -Tunnel none          # hanya IP LAN (1 WiFi dengan sandbox)
#
# PERINGATAN: adb yang terbuka = kontrol penuh atas HP (install app, baca data, screenshot).
# Matikan tunnel setelah selesai.
param(
    [string]$Model = 'V2318',
    [int]$Port = 5555,
    [ValidateSet('auto', 'ngrok', 'tailscale', 'none')]
    [string]$Tunnel = 'auto',
    [int]$FunnelPort = 10000,
    [int]$TunnelWaitSec = 25,
    [string]$Serial
)

$ErrorActionPreference = 'Stop'

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
    throw "adb tidak ditemukan. Set ANDROID_HOME atau install Android SDK Platform-Tools."
}

$adb = Get-AdbPath
Write-Host "=== Expose vivo V30 (model $Model) untuk agen ===" -ForegroundColor Cyan
& $adb start-server | Out-Null

function Get-DeviceList {
    & $adb devices -l | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
}

$target = $Serial
if (-not $target) {
    $target = ((Get-DeviceList | Where-Object { $_ -match [regex]::Escape($Model) } | Select-Object -First 1) -split '\s+' | Select-Object -First 1)
}
if (-not $target) {
    $target = ((Get-DeviceList | Where-Object { $_ -notmatch '^emulator-' } | Select-Object -First 1) -split '\s+' | Select-Object -First 1)
}
if (-not $target) {
    throw "Tidak ada perangkat terdeteksi. Colok USB + aktifkan USB debugging, lalu ulangi."
}

Write-Host "[+] Device USB: $target" -ForegroundColor Green

# --- 1. Aktifkan adb tcpip pada perangkat ---
& $adb -s $target tcpip $Port
Start-Sleep -Seconds 2

# --- 2. Cari IP Wi-Fi perangkat ---
$route = (& $adb -s $target shell ip route) -join ' '
$deviceIp = $null
if ($route -match 'src\s+(\d{1,3}(?:\.\d{1,3}){3})') { $deviceIp = $Matches[1] }
if (-not $deviceIp) {
    $addr = (& $adb -s $target shell ip -f inet addr show wlan0) -join ' '
    if ($addr -match 'inet\s+(\d{1,3}(?:\.\d{1,3}){3})') { $deviceIp = $Matches[1] }
}

Write-Host ''
if ($deviceIp) {
    Write-Host "[+] Endpoint LAN: ${deviceIp}:$Port" -ForegroundColor Green
    Write-Host "    (bisa dipakai kalau sandbox satu jaringan dengan HP: adb connect ${deviceIp}:$Port)"
} else {
    Write-Host "[!] IP Wi-Fi perangkat tidak terdeteksi - cek Wi-Fi aktif di HP." -ForegroundColor Yellow
}

# --- 3. Tunnel TCP publik (opsional) ---
function Get-NgrokEndpoint {
    param([int]$TimeoutSec = 25)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $api = Invoke-RestMethod -Uri 'http://127.0.0.1:4040/api/tunnels' -TimeoutSec 3
            $tcp = $api.tunnels | Where-Object { $_.public_url -like 'tcp://*' } | Select-Object -First 1
            if ($tcp) { return ($tcp.public_url -replace '^tcp://', '') }
        } catch { }
        Start-Sleep -Seconds 2
    }
    return $null
}

$endpoint = $null
$chosen = $Tunnel
if ($Tunnel -eq 'auto') {
    if (Get-Command ngrok -ErrorAction SilentlyContinue) { $chosen = 'ngrok' }
    elseif (Get-Command tailscale -ErrorAction SilentlyContinue) { $chosen = 'tailscale' }
    else { $chosen = 'none' }
}

switch ($chosen) {
    'ngrok' {
        $ngrok = (Get-Command ngrok -ErrorAction SilentlyContinue).Source
        if (-not $ngrok) {
            Write-Host "[!] ngrok tidak ada di PATH. Install: https://ngrok.com/download" -ForegroundColor Yellow
            break
        }
        Write-Host "[*] Menjalankan: ngrok tcp $Port" -ForegroundColor Yellow
        Start-Process -FilePath $ngrok -ArgumentList @('tcp', "$Port")
        $endpoint = Get-NgrokEndpoint -TimeoutSec $TunnelWaitSec
        if (-not $endpoint) {
            Write-Host "[!] Gagal membaca endpoint ngrok dari http://127.0.0.1:4040/api/tunnels" -ForegroundColor Yellow
        }
    }
    'tailscale' {
        $ts = (Get-Command tailscale -ErrorAction SilentlyContinue).Source
        if (-not $ts) {
            Write-Host "[!] tailscale tidak ada di PATH. Install: https://tailscale.com/download" -ForegroundColor Yellow
            break
        }
        Write-Host "[*] Menjalankan: tailscale funnel --bg --tcp=$FunnelPort tcp://localhost:$Port" -ForegroundColor Yellow
        & $ts funnel --bg "--tcp=$FunnelPort" "tcp://localhost:$Port"
        $status = (& $ts status --json) -join ''
        $dns = $null
        if ($status -match '"DNSName"\s*:\s*"([^"]+)"') { $dns = $Matches[1].TrimEnd('.') }
        if ($dns) { $endpoint = "${dns}:$FunnelPort" }
        else { Write-Host "[!] Tidak bisa membaca DNSName tailscale - jalankan 'tailscale funnel status'." -ForegroundColor Yellow }
    }
    default {
        Write-Host "[i] Tanpa tunnel. Pakai -Tunnel ngrok / -Tunnel tailscale bila agen perlu akses dari cloud." -ForegroundColor DarkGray
    }
}

# --- 4. Ringkasan untuk agen ---
Write-Host ''
Write-Host '=== Yang dibutuhkan agen (Cline) ===' -ForegroundColor Cyan
if ($endpoint) {
    Write-Host "adb connect $endpoint" -ForegroundColor Green
    Write-Host "adb -s $endpoint shell getprop ro.product.model" -ForegroundColor Green
    Write-Host ''
    Write-Host 'Kirim baris di atas ke agen. Matikan tunnel setelah selesai:' -ForegroundColor Yellow
    if ($chosen -eq 'ngrok') { Write-Host '  Ctrl+C di jendela ngrok (atau: taskkill /IM ngrok.exe /F)' }
    if ($chosen -eq 'tailscale') { Write-Host "  tailscale funnel --tcp=$FunnelPort tcp://localhost:$Port off" }
} else {
    Write-Host '(belum ada endpoint publik - tidak ada yang bisa dikirim ke agen)' -ForegroundColor DarkGray
}
Write-Host ''
Write-Host 'PERINGATAN: selama tunnel hidup, siapa pun yang tahu endpoint bisa mengontrol HP ini.' -ForegroundColor Red
