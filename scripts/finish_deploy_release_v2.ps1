# Selesaikan deploy release_v2 — server-side extract atau git push.
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

Write-Host 'Fallback: deploy_git.ps1 + git push (FTP diblokir)' -ForegroundColor Yellow
& (Join-Path $root 'scripts\deploy_git.ps1') -Layer all -WebRenderer html
Write-Host 'Lanjut: git add build/deploy build/deploy_api && git commit && git push origin main'
