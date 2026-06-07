# Picu git pull + .cpanel.yml di server via deploy_trigger.php (port 443, tanpa FTP/2083).
param(
    [string]$Branch = 'main',
    [string]$ApiBase = 'https://api.kakiempat.com'
)

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

$secret = $env:GIT_DEPLOY_SECRET
if (-not $secret -and (Test-Path $credPath)) {
    $ini = Get-Content $credPath -Raw
    $secret = Get-IniValue $ini 'git_deploy' 'secret'
}
if (-not $secret) {
    throw 'GIT_DEPLOY_SECRET tidak ditemukan. Set env GIT_DEPLOY_SECRET atau [git_deploy] secret di hosting.credentials'
}

$url = "${ApiBase}/deploy_trigger.php?branch=$([uri]::EscapeDataString($Branch))&secret=$([uri]::EscapeDataString($secret))"
Write-Host "Memicu deploy: $url" -ForegroundColor Cyan
$out = curl.exe -sS -w "`nHTTP:%{http_code}" --max-time 300 -H "X-Deploy-Secret: $secret" $url
Write-Host $out

if ($out -notmatch 'HTTP:200' -or $out -notmatch '"ok":true') {
    throw 'deploy_trigger.php gagal — pastikan bootstrap_deploy_hook sudah jalan di GitHub Actions'
}
Write-Host 'OK — server git pull + .cpanel.yml' -ForegroundColor Green
