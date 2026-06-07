# FTP upload helpers — dipakai deploy_via_ftp.ps1, deploy_api_owner.ps1, dll.

function Get-HostingFtpCredentials {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $credPath = Join-Path $ProjectRoot '.cursor\secrets\hosting.credentials'
    if (-not (Test-Path $credPath)) {
        throw "Missing $credPath - copy from hosting.credentials.example"
    }

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
    $user = Get-IniValue $ini 'cpanel' 'username'
    $pass = Get-IniValue $ini 'cpanel' 'password'
    $primary = Get-IniValue $ini 'cpanel' 'primary_domain'
    $sharedIp = Get-IniValue $ini 'cpanel' 'shared_ip'
    if (-not $user -or -not $pass) {
        throw 'cpanel username/password required in hosting.credentials'
    }

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

function Initialize-FtpHost {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials
    )

    if ($script:ActiveFtpHost) { return $script:ActiveFtpHost }

    foreach ($h in $Credentials.Hosts) {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            curl.exe -sS --connect-timeout 30 --ftp-pasv `
                -u "$($Credentials.User):$($Credentials.Pass)" `
                "ftp://${h}/" 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $script:ActiveFtpHost = $h
                Write-Host "FTP host aktif: $h" -ForegroundColor Green
                return $h
            }
        } finally {
            $ErrorActionPreference = $prev
        }
    }
    throw "Tidak bisa konek FTP ke host: $($Credentials.Hosts -join ', ')"
}

function Send-FtpFile {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials,
        [Parameter(Mandatory)]
        [string]$LocalPath,
        [Parameter(Mandatory)]
        [string]$RemotePath
    )

    if (-not (Test-Path $LocalPath)) {
        throw "File lokal tidak ada: $LocalPath"
    }

    Initialize-FtpHost -Credentials $Credentials | Out-Null
    $remote = $RemotePath.TrimStart('/').Replace('\', '/')
    $dir = Split-Path $remote -Parent
    if ($dir) {
        $segments = $dir -split '/'
        $acc = ''
        foreach ($seg in $segments) {
            if (-not $seg) { continue }
            $acc = if ($acc) { "$acc/$seg" } else { $seg }
            curl.exe -sS --ftp-pasv -u "$($Credentials.User):$($Credentials.Pass)" `
                "ftp://${script:ActiveFtpHost}/" -Q "MKD $acc" 2>$null | Out-Null
        }
    }

    Write-Host "[FTP] $remote"
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        curl.exe -sS --connect-timeout 30 --max-time 300 --ftp-create-dirs --ftp-pasv `
            -u "$($Credentials.User):$($Credentials.Pass)" `
            -T $LocalPath "ftp://${script:ActiveFtpHost}/${remote}" 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "FTP gagal $remote (curl exit $LASTEXITCODE)"
        }
    } finally {
        $ErrorActionPreference = $prev
    }
}

function Send-FtpFileList {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Credentials,
        [Parameter(Mandatory)]
        [object[]]$Files
    )

    foreach ($item in $Files) {
        Send-FtpFile -Credentials $Credentials -LocalPath $item.Local -RemotePath $item.Remote
    }
}
