# Generate .vscode/ftp.json dari hosting.credentials (MVP: api, owner, sitter).
param(
    [ValidateSet('api', 'owner', 'sitter', 'all')]
    [string]$Profile = 'all'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
$outDir = Join-Path $root '.vscode'

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

if (-not (Test-Path $credPath)) {
    throw "Missing $credPath - copy from .cursor/secrets/hosting.credentials.example"
}

$ini = Get-Content $credPath -Raw
$user = Get-IniValue $ini 'cpanel' 'username'
$pass = Get-IniValue $ini 'cpanel' 'password'
$sharedIp = Get-IniValue $ini 'cpanel' 'shared_ip'
if (-not $user -or -not $pass) { throw 'cpanel username/password required in hosting.credentials' }

$ftpHost = if ($sharedIp) { $sharedIp } else { 'ftp.kakiempat.com' }

$profiles = @{
    api = @{
        name       = 'kakiempat-api'
        localPath  = 'build/deploy_api'
        remotePath = 'api.kakiempat.com'
    }
    owner = @{
        name       = 'kakiempat-owner'
        localPath  = 'build/web'
        remotePath = 'owner.kakiempat.com'
    }
    sitter = @{
        name       = 'kakiempat-sitter'
        localPath  = 'build/web'
        remotePath = 'sitter.kakiempat.com'
    }
}

$ignore = @(
    '.git/**', 'node_modules/**', 'vendor/**', 'storage/logs/**',
    'backups/**', 'uploads/**',
    '.mysql_v2.php', '.migrate_v2_secret',
    '.payment_webhook_secret', '.payment_config.php'
)

function New-FtpConfig($key) {
    $p = $profiles[$key]
    $cfg = [ordered]@{
        name         = $p.name
        scheme       = 'ftp'
        username     = $user
        password     = $pass
        localPath    = "`${workspaceFolder}/$($p.localPath)"
        remotePath   = $p.remotePath
        uploadOnSave = $false
        ignore       = $ignore
    }
    $cfg['host'] = [string]$ftpHost
    return $cfg
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$selected = if ($Profile -eq 'all') { @('api', 'owner', 'sitter') } else { @($Profile) }

foreach ($key in $selected) {
    $cfg = New-FtpConfig $key
    $outFile = Join-Path $outDir "ftp-$key.json"
    $cfg | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8
    Write-Host "Wrote $outFile (remote: $($profiles[$key].remotePath))"
}

# Default aktif: API (perbaikan dari remotePath /public_html/api/ yang salah).
New-FtpConfig 'api' | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $outDir 'ftp.json') -Encoding UTF8
Write-Host 'Wrote .vscode/ftp.json (profile: kakiempat-api)' -ForegroundColor Green
Write-Host 'Do not commit ftp.json or ftp-*.json (listed in .gitignore).'
