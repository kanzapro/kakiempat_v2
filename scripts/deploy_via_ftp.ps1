# Upload build web + API schema ke cPanel via FTP (kredensial [cpanel] di hosting.credentials).
param(
    [ValidateSet('api', 'www', 'owner', 'sitter', 'admin', 'staging', 'all')]
    [string]$Target = 'all'
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

if (-not (Test-Path $credPath)) { throw "Missing $credPath" }
$ini = Get-Content $credPath -Raw
$ftpUser = Get-IniValue $ini 'cpanel' 'username'
$ftpPass = Get-IniValue $ini 'cpanel' 'password'
if (-not $ftpUser -or -not $ftpPass) { throw 'cpanel username/password required' }

$sharedIp = Get-IniValue $ini 'cpanel' 'shared_ip'
$primary = Get-IniValue $ini 'cpanel' 'primary_domain'
$ftpHosts = @(
    $(if ($sharedIp) { $sharedIp }),
    'ftp.kakiempat.com',
    $(if ($primary) { $primary })
) | Where-Object { $_ } | Select-Object -Unique
$ftpHost = $ftpHosts[0]
$docroots = @{
    api     = 'api.kakiempat.com'
    www     = 'public_html'
    owner   = 'owner.kakiempat.com'
    sitter  = 'sitter.kakiempat.com'
    admin   = 'admin.kakiempat.com'
    staging = 'staging.kakiempat.com'
}

$script:ActiveFtpHost = $null

function Send-FtpFile([string]$local, [string]$remote) {
    $remote = $remote.TrimStart('/').Replace('\', '/')
    if (-not $script:ActiveFtpHost) {
        foreach ($h in $ftpHosts) {
            $prev = $ErrorActionPreference
            $ErrorActionPreference = 'Continue'
            try {
                curl.exe -sS --connect-timeout 30 --ftp-pasv -u "${ftpUser}:${ftpPass}" `
                    -T $local "ftp://${h}/${remote}" 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $script:ActiveFtpHost = $h
                    Write-Host "FTP host aktif: $h" -ForegroundColor Green
                    return
                }
            } finally {
                $ErrorActionPreference = $prev
            }
        }
        throw "Tidak bisa konek FTP ke host: $($ftpHosts -join ', ')"
    }
    $dir = Split-Path $remote -Parent
    if ($dir) {
        $segments = $dir -split '/'
        $acc = ''
        foreach ($seg in $segments) {
            if (-not $seg) { continue }
            $acc = if ($acc) { "$acc/$seg" } else { $seg }
            curl.exe -sS --ftp-pasv -u "${ftpUser}:${ftpPass}" `
                "ftp://${script:ActiveFtpHost}/" -Q "MKD $acc" 2>$null | Out-Null
        }
    }
    Write-Host "[FTP] $remote"
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        curl.exe -sS --connect-timeout 30 --max-time 300 --ftp-create-dirs --ftp-pasv `
            -u "${ftpUser}:${ftpPass}" -T $local "ftp://${script:ActiveFtpHost}/${remote}" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "FTP gagal $remote (curl exit $LASTEXITCODE)"
        }
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Upload-Dir([string]$localDir, [string]$remoteBase) {
    Get-ChildItem -LiteralPath $localDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($localDir.Length).TrimStart('\').Replace('\', '/')
        Send-FtpFile $_.FullName "$remoteBase/$rel"
    }
}

$targets = if ($Target -eq 'all') { @('api', 'www', 'owner', 'sitter', 'admin', 'staging') } else { @($Target) }

foreach ($t in $targets) {
    $remote = $docroots[$t]
    if ($t -eq 'api') {
        $apiSrc = Join-Path $root 'build\deploy_api'
        if (-not (Test-Path $apiSrc)) {
            & (Join-Path $root 'scripts\deploy_api.ps1')
        }
        Upload-Dir $apiSrc $remote
        continue
    }
    $webSrc = Join-Path $root 'build\web'
    if (-not (Test-Path $webSrc)) { throw "Build web tidak ada: $webSrc" }
    Upload-Dir $webSrc $remote
}

Write-Host 'FTP upload selesai.' -ForegroundColor Green
