# Selesaikan deploy release_v2 setelah IP di-whitelist Imunify360.
# Prioritas: PHP extract server-side (cepat), fallback FTP per-file.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

$ini = Get-Content $credPath -Raw
$secret = $null
foreach ($k in @('deploy_secret', 'media_secret')) {
    $v = Get-IniValue $ini 'cpanel' $k
    if ($v) { $secret = $v; break }
}

if (-not $secret) {
    Write-Host 'Coba extract via secret di server (.kakiempat_media_secret)...'
    $user = Get-IniValue $ini 'cpanel' 'username'
    $pass = Get-IniValue $ini 'cpanel' 'password'
    $secret = (curl.exe -sS --ftp-pasv -u "${user}:${pass}" 'ftp://ftp.kakiempat.com/public_html/api/.kakiempat_media_secret' 2>$null).Trim()
}

if ($secret) {
    Write-Host 'Trigger deploy-release-v2-all-extract.php ...'
    $urls = @(
        "https://kakiempat.com/deploy-release-v2-all-extract.php?run=1&key=$secret",
        "https://www.kakiempat.com/deploy-release-v2-all-extract.php?run=1&key=$secret"
    )
    foreach ($u in $urls) {
        $out = curl.exe -sS -L --connect-timeout 300 -H 'Accept: text/plain' $u 2>&1
        Write-Host $out
        if ($out -match 'DONE deploy-release-v2-all-extract') {
            Write-Host 'Extract server-side OK.' -ForegroundColor Green
            exit 0
        }
    }
}

Write-Host 'Fallback: scripts/deploy_release_zip_all.ps1' -ForegroundColor Yellow
& (Join-Path $root 'scripts\deploy_release_zip_all.ps1')
