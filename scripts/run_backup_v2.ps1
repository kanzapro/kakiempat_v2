# Jalankan backup database v2 via HTTP (manual / CI).
param(
    [string]$ApiBase = 'https://api.kakiempat.com',
    [string]$SecretIniSection = 'api_deploy',
    [string]$SecretIniKey = 'migrate_secret'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

$secret = $null

$envFile = Join-Path $root '.env'
if (Test-Path $envFile) {
    foreach ($line in Get-Content $envFile) {
        $t = $line.Trim()
        if ($t -match '^V2_MIGRATE_SECRET=(.+)$') {
            $secret = $Matches[1].Trim().Trim('"').Trim("'")
            break
        }
    }
}

if (-not $secret) {
    $credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
    if (Test-Path $credPath) {
        $ini = Get-Content $credPath -Raw
        $secret = Get-IniValue $ini $SecretIniSection $SecretIniKey
    }
}

if (-not $secret) {
    throw 'Secret backup tidak ditemukan (.env V2_MIGRATE_SECRET atau hosting.credentials [api_deploy] migrate_secret).'
}

$qKey = [uri]::EscapeDataString($secret)
$url = "${ApiBase}/backup_db_v2.php?key=${qKey}"
Write-Host "Backup v2: $ApiBase ..."
$body = curl.exe -sS -A 'Mozilla/5.0' -H 'Accept: application/json' $url
Write-Host $body
