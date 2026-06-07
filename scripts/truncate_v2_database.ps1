# TRUNCATE semua tabel kakiempa_v2 via mysql CLI (remote jika diizinkan cPanel).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
$sqlPath = Join-Path $root 'scripts\db\truncate_kakiempa_v2.sql'

if (-not (Test-Path $credPath)) {
    Write-Error "Missing $credPath"
}
if (-not (Test-Path $sqlPath)) {
    Write-Error "Missing $sqlPath"
}

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') {
            $in = ($Matches[1] -eq $section)
            continue
        }
        if ($in -and $t -match "^$key=(.*)$") {
            return $Matches[1].Trim()
        }
    }
    return $null
}

$ini = Get-Content $credPath -Raw
$dbHost = Get-IniValue $ini 'mysql_v2' 'host'
$database = Get-IniValue $ini 'mysql_v2' 'database'
$user = Get-IniValue $ini 'mysql_v2' 'user'
$pass = Get-IniValue $ini 'mysql_v2' 'password'

# cPanel: coba host remote domain jika localhost
$hosts = @()
if ($dbHost -eq 'localhost') {
    $hosts = @('kakiempat.com', '178.83.188.195')
} else {
    $hosts = @($dbHost)
}

$mysql = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysql) {
    Write-Warning 'mysql CLI tidak ditemukan. Jalankan scripts/db/truncate_kakiempa_v2.sql lewat phpMyAdmin cPanel.'
    exit 2
}

foreach ($h in $hosts) {
    Write-Host "Trying mysql -h $h -u $user $database ..."
    $env:MYSQL_PWD = $pass
    & mysql -h $h -u $user $database -e "source $($sqlPath -replace '\\','/')"
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'TRUNCATE selesai.'
        exit 0
    }
}

Write-Warning 'Koneksi mysql gagal. Kosongkan DB manual: phpMyAdmin > kakiempa_v2 > impor scripts/db/truncate_kakiempa_v2.sql'
exit 1
