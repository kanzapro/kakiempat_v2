# Retry upload file API yang gagal (Imunify360).
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

$ini = Get-Content (Join-Path $root '.cursor\secrets\hosting.credentials') -Raw
$user = Get-IniValue $ini 'cpanel' 'username'
$pass = Get-IniValue $ini 'cpanel' 'password'
$remoteBase = '/home/kakiempa/api.kakiempat.com'
$names = @('get_notifications.php', 'get_unread_notifications.php', 'health.php', 'index.php')

foreach ($name in $names) {
    Start-Sleep -Seconds 10
    $local = Join-Path $root "build\deploy_api\$name"
    $out = curl.exe -sS --connect-timeout 60 --max-time 180 -u "${user}:${pass}" `
        -H 'Accept: application/json' `
        'https://kakiempat.com:2083/execute/Fileman/save_file_content' `
        --data-urlencode "dir=$remoteBase" `
        --data-urlencode "file=$name" `
        --data-urlencode "content@$local" 2>&1
    if ($out -match '"status":1') { Write-Host "[OK] $name" -ForegroundColor Green }
    else { Write-Host "[FAIL] $name : $out" -ForegroundColor Red }
}
