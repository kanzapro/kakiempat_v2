# Shared FTP helpers for deploy scripts (cPanel, passive mode).
$ErrorActionPreference = 'Stop'

function Get-HostingIniValue {
    param([string]$Text, [string]$Section, [string]$Key)
    $in = $false
    foreach ($line in $Text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $Section); continue }
        if ($in -and $t -match "^$Key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

function Get-FtpCredentials {
    param([string]$ProjectRoot)
    $credPath = Join-Path $ProjectRoot '.cursor\secrets\hosting.credentials'
    if (-not (Test-Path $credPath)) { throw "Missing $credPath" }
    $ini = Get-Content $credPath -Raw
    $user = Get-HostingIniValue $ini 'cpanel' 'username'
    $pass = Get-HostingIniValue $ini 'cpanel' 'password'
    $sharedIp = Get-HostingIniValue $ini 'cpanel' 'shared_ip'
    $primary = Get-HostingIniValue $ini 'cpanel' 'primary_domain'
    if (-not $user -or -not $pass) { throw 'cpanel username/password required' }
    $hosts = @(
        $(if ($sharedIp) { $sharedIp }),
        'ftp.kakiempat.com',
        $(if ($primary) { $primary })
    ) | Where-Object { $_ } | Select-Object -Unique
    return @{
        User  = $user
        Pass  = $pass
        Hosts = $hosts
    }
}

function Send-FtpFileToApi {
    param(
        [string]$LocalFile,
        [string]$RemoteRelativePath,
        [string]$User,
        [string]$Pass,
        [ref]$ActiveHost,
        [string[]]$Hosts
    )
    if (-not (Test-Path $LocalFile)) { throw "Local file missing: $LocalFile" }
    $remote = $RemoteRelativePath.TrimStart('/').Replace('\', '/')
    $remoteBase = 'api.kakiempat.com'
    $targetHosts = if ($ActiveHost.Value) { @($ActiveHost.Value) } else { $Hosts }

    $dir = Split-Path $remote -Parent
    foreach ($h in $targetHosts) {
        if ($dir) {
            $segments = $dir -split '/'
            $acc = $remoteBase
            foreach ($seg in $segments) {
                if (-not $seg) { continue }
                $acc = "$acc/$seg"
                curl.exe -sS --ftp-pasv -u "${User}:${Pass}" `
                    "ftp://${h}/" -Q "MKD $acc" 2>$null | Out-Null
            }
        }

        Write-Host "[FTP] ${remoteBase}/${remote}" -ForegroundColor Cyan
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            curl.exe -sS --connect-timeout 30 --max-time 300 --ftp-create-dirs --ftp-pasv `
                -u "${User}:${Pass}" -T $LocalFile "ftp://${h}/${remoteBase}/${remote}" 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                if (-not $ActiveHost.Value) {
                    $ActiveHost.Value = $h
                    Write-Host "FTP host aktif: $h" -ForegroundColor Green
                }
                return
            }
        } finally {
            $ErrorActionPreference = $prev
        }
    }
    throw "FTP gagal ${remoteBase}/${remote}"
}
