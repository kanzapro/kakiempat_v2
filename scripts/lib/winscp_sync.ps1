# WinSCP .NET assembly — sinkronisasi lokal ke remote (hanya file berubah).
# Runtime di-bootstrap otomatis dari paket NuGet WinSCP jika belum ada.

$script:WinScpExecutable = $null

function Get-WinScpRuntimeDir {
    param(
        [Parameter(Mandatory)]
        [string]$LibRoot
    )

    $runtimeDir = Join-Path $LibRoot 'winscp'
    $dll = Join-Path $runtimeDir 'WinSCPnet.dll'
    $exe = Join-Path $runtimeDir 'WinSCP.exe'
    if ((Test-Path $dll) -and (Test-Path $exe)) {
        return $runtimeDir
    }

    foreach ($installed in @(
            "${env:ProgramFiles(x86)}\WinSCP",
            "$env:ProgramFiles\WinSCP"
        )) {
        $installedDll = Join-Path $installed 'WinSCPnet.dll'
        $installedExe = Join-Path $installed 'WinSCP.exe'
        if ((Test-Path $installedDll) -and (Test-Path $installedExe)) {
            return $installed
        }
    }

    if ($env:WINSCP_DLL) {
        $customDir = Split-Path -Parent $env:WINSCP_DLL
        $customExe = Join-Path $customDir 'WinSCP.exe'
        if ((Test-Path $env:WINSCP_DLL) -and (Test-Path $customExe)) {
            return $customDir
        }
    }

    Write-Host 'WinSCP runtime belum ada — mengunduh paket NuGet WinSCP ...' -ForegroundColor Yellow
    $cacheDir = Join-Path $LibRoot '.winscp'
    if (Test-Path $cacheDir) { Remove-Item $cacheDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

    $nupkg = Join-Path ([IO.Path]::GetTempPath()) "winscp-$([Guid]::NewGuid().ToString('N')).zip"
    try {
        Invoke-WebRequest -Uri 'https://www.nuget.org/api/v2/package/WinSCP/6.3.7' `
            -OutFile $nupkg -UseBasicParsing
        Expand-Archive -Path $nupkg -DestinationPath $cacheDir -Force
    } finally {
        if (Test-Path $nupkg) { Remove-Item $nupkg -Force }
    }

    $srcDll = Get-ChildItem -Path $cacheDir -Recurse -Filter 'WinSCPnet.dll' |
        Where-Object { $_.DirectoryName -match 'netstandard2\.0' } |
        Select-Object -First 1
    $srcExe = Get-ChildItem -Path $cacheDir -Recurse -Filter 'WinSCP.exe' |
        Select-Object -First 1
    if (-not $srcDll -or -not $srcExe) {
        throw 'Bootstrap WinSCP gagal: WinSCPnet.dll / WinSCP.exe tidak ditemukan di paket NuGet.'
    }

    New-Item -ItemType Directory -Force -Path $runtimeDir | Out-Null
    Copy-Item $srcDll.FullName $dll -Force
    Copy-Item $srcExe.FullName $exe -Force
    Write-Host "WinSCP runtime siap: $runtimeDir" -ForegroundColor Green
    return $runtimeDir
}

function Initialize-WinScpAssembly {
    param(
        [Parameter(Mandatory)]
        [string]$LibRoot
    )

    if (-not ('WinSCP.Session' -as [type])) {
        $runtimeDir = Get-WinScpRuntimeDir -LibRoot $LibRoot
        Add-Type -Path (Join-Path $runtimeDir 'WinSCPnet.dll')
    }
    if (-not $script:WinScpExecutable) {
        $runtimeDir = Get-WinScpRuntimeDir -LibRoot $LibRoot
        $script:WinScpExecutable = Join-Path $runtimeDir 'WinSCP.exe'
    }
}

function Invoke-WinScpSyncLocalToRemote {
    param(
        [Parameter(Mandatory)]
        [string]$LocalPath,
        [Parameter(Mandatory)]
        [string]$RemotePath,
        [Parameter(Mandatory)]
        [string]$UserName,
        [Parameter(Mandatory)]
        [string]$Password,
        [Parameter(Mandatory)]
        [string[]]$HostNames,
        [Parameter(Mandatory)]
        [string]$LibRoot,
        [switch]$DeleteRemoteExtra
    )

    if (-not (Test-Path $LocalPath)) {
        throw "Folder lokal tidak ada: $LocalPath"
    }

    Initialize-WinScpAssembly -LibRoot $LibRoot

    $remotePath = $RemotePath.Trim().TrimStart('/').Replace('\', '/')
    $activeHost = $null
    $syncResult = $null

    foreach ($hostName in ($HostNames | Where-Object { $_ } | Select-Object -Unique)) {
        Write-Host "  WinSCP coba host: $hostName ..." -ForegroundColor DarkGray
        $session = New-Object WinSCP.Session
        try {
            $session.ExecutablePath = $script:WinScpExecutable
            $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::Ftp
                HostName = $hostName
                UserName = $UserName
                Password = $Password
                FtpMode  = [WinSCP.FtpMode]::Passive
            }
            $sessionOptions.Timeout = [TimeSpan]::FromSeconds(120)
            $session.Open($sessionOptions)
            $activeHost = $hostName
            Write-Host "  WinSCP terhubung: $hostName" -ForegroundColor Green

            $transferOptions = New-Object WinSCP.TransferOptions
            $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

            Write-Host "WinSCP sync local -> remote (${activeHost}:/$remotePath) ..." -ForegroundColor Cyan
            $syncResult = $session.SynchronizeDirectories(
                [WinSCP.SynchronizationMode]::Local,
                $LocalPath,
                $remotePath,
                $DeleteRemoteExtra.IsPresent,
                $false,
                [WinSCP.SynchronizationCriteria]::Time,
                $transferOptions
            )
            break
        } catch {
            Write-Host "  Host $hostName gagal: $($_.Exception.Message)" -ForegroundColor Yellow
        } finally {
            if ($session.Opened) { $session.Dispose() }
        }
    }

    if (-not $syncResult) {
        throw @(
            'Tidak bisa konek FTP via WinSCP.',
            "Host dicoba: $($HostNames -join ', ')",
            'Cek: firewall ISP/VPN, cPanel FTP aktif, IP tidak diblokir.'
        ) -join ' '
    }

    $uploadCount = @($syncResult.Uploads).Count
    $removeCount = @($syncResult.Removals).Count
    if ($uploadCount -gt 0) {
        foreach ($transfer in $syncResult.Uploads) {
            Write-Host "  + $($transfer.FileName)" -ForegroundColor Green
        }
    } else {
        Write-Host '  Tidak ada file baru/berubah — remote sudah sinkron.' -ForegroundColor DarkGray
    }
    if ($removeCount -gt 0) {
        foreach ($transfer in $syncResult.Removals) {
            Write-Host "  - $($transfer.FileName)" -ForegroundColor Yellow
        }
    }

    $syncResult.Check()
    Write-Host "WinSCP OK: $uploadCount upload, $removeCount hapus via $activeHost" -ForegroundColor Green
}
