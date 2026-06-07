# Deploy ulang semua subdomain dari ZIP identik build/release_v2/
param(
    [string]$ZipName = 'www-deploy.zip'
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
if (-not $ftpUser -or -not $ftpPass) { throw 'cpanel credentials required' }

$ftpHost = 'ftp.kakiempat.com'
$releaseDir = Join-Path $root 'build\release_v2'
$zipPath = Join-Path $releaseDir $ZipName
if (-not (Test-Path $zipPath)) { throw "Missing $zipPath" }

$targets = [ordered]@{
    www    = @{ remote = 'public_html'; mode = 'flutter-only' }
    owner  = @{ remote = 'owner.kakiempat.com'; mode = 'full-except-api' }
    sitter = @{ remote = 'sitter.kakiempat.com'; mode = 'full-except-api' }
    admin  = @{ remote = 'admin.kakiempat.com'; mode = 'full-except-api' }
}

$flutterArtifacts = @(
    'assets', 'canvaskit', 'icons', 'index.html', 'main.dart.js',
    'flutter.js', 'flutter_bootstrap.js', 'flutter_service_worker.js',
    'manifest.json', 'version.json', 'favicon.png', '.last_build_id',
    'flutter-assets', 'www-deploy.zip', 'owner-deploy.zip',
    'sitter-deploy.zip', 'admin-deploy.zip', 'kakiempat-web-cpanel.zip',
    'owner-subdomain-web.zip'
)

$extractRoot = Join-Path $root 'build\_deploy_extract'
if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
Write-Host "Extract $ZipName -> $extractRoot"
Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

$mainLocal = Join-Path $extractRoot 'main.dart.js'
if (-not (Test-Path $mainLocal)) { throw 'main.dart.js missing in ZIP' }
$mainBytes = (Get-Item $mainLocal).Length
$mainMd5 = (Get-FileHash $mainLocal -Algorithm MD5).Hash
Write-Host "Bundle: main.dart.js $mainBytes bytes, MD5 $mainMd5"

function Invoke-Curl([string[]]$CurlArgs) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $out = & curl.exe @CurlArgs 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prev
    return @{ out = ($out -join "`n"); code = $code }
}

function Test-FtpDir([string]$remotePath) {
    $url = "ftp://${ftpHost}/$remotePath/"
    $r = Invoke-Curl @('-sS', '--connect-timeout', '30', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", $url, '--list-only')
    if ($r.code -ne 0) { return $false }
    $text = [string]$r.out
    return ($text.Length -gt 0 -and $text -notmatch '550|Could not|denied|failed|No such file')
}

function Remove-FtpPath([string]$remotePath) {
    if ($remotePath -match '(^|/)api(/|$)') { return }
    if (Test-FtpDir $remotePath) {
        $r = Invoke-Curl @('-sS', '--connect-timeout', '30', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", "ftp://${ftpHost}/$remotePath/", '--list-only')
        foreach ($item in ($r.out -split "`n")) {
            $item = $item.Trim()
            if (-not $item -or $item -eq '.' -or $item -eq '..') { continue }
            if ($item -eq 'api') { continue }
            Remove-FtpPath "$remotePath/$item"
        }
        Write-Host "  [RMD] $remotePath"
        Invoke-Curl @('-sS', '--connect-timeout', '30', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", "ftp://${ftpHost}/", '-Q', "RMD $remotePath") | Out-Null
        return
    }
    Write-Host "  [DELE] $remotePath"
    Invoke-Curl @('-sS', '--connect-timeout', '30', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", "ftp://${ftpHost}/", '-Q', "DELE $remotePath") | Out-Null
}

function Send-FtpFile([string]$local, [string]$remote) {
    $remote = $remote.TrimStart('/').Replace('\', '/')
    $url = "ftp://${ftpHost}/${remote}"
    $r = Invoke-Curl @('-sS', '--connect-timeout', '120', '--ftp-create-dirs', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", '-T', $local, $url)
    if ($r.code -ne 0 -and $r.out -notmatch '226') { throw "FTP upload gagal $remote : $($r.out)" }
}

function Upload-Dir([string]$localDir, [string]$remoteBase) {
    Get-ChildItem -LiteralPath $localDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($localDir.Length).TrimStart('\').Replace('\', '/')
        Write-Host "  [PUT] $remoteBase/$rel"
        Send-FtpFile $_.FullName "$remoteBase/$rel"
    }
}

$verify = @{}
foreach ($entry in $targets.GetEnumerator()) {
    $name = $entry.Key
    $remoteBase = $entry.Value.remote
    $mode = $entry.Value.mode
    Write-Host "`n=== Deploy $name -> $remoteBase ($mode) ===" -ForegroundColor Cyan

    Write-Host 'Clean docroot...'
    if ($mode -eq 'full-except-api') {
        $r = Invoke-Curl @('-sS', '--connect-timeout', '30', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", "ftp://${ftpHost}/$remoteBase/", '--list-only')
        foreach ($item in ($r.out -split "`n")) {
            $item = $item.Trim()
            if (-not $item -or $item -eq '.' -or $item -eq '..') { continue }
            if ($item -eq 'api') { continue }
            Remove-FtpPath "$remoteBase/$item"
        }
    } else {
        foreach ($artifact in $flutterArtifacts) {
            $path = "$remoteBase/$artifact"
            if ($artifact -in @('assets', 'canvaskit', 'icons', 'flutter-assets')) {
                if (Test-FtpDir $path) { Remove-FtpPath $path }
                continue
            }
            Remove-FtpPath $path
        }
    }

    Write-Host 'Upload bundle...'
    Upload-Dir $extractRoot $remoteBase

    $tmpMain = Join-Path $root "build\ftp_check_${remoteBase.Replace('/','_')}_main.dart.js"
    if (Test-Path $tmpMain) { Remove-Item $tmpMain -Force }
    Invoke-Curl @('-sS', '--connect-timeout', '120', '--ftp-pasv', '-u', "${ftpUser}:${ftpPass}", "ftp://${ftpHost}/$remoteBase/main.dart.js", '-o', $tmpMain) | Out-Null
    if (Test-Path $tmpMain) {
        $sz = (Get-Item $tmpMain).Length
        $md5 = (Get-FileHash $tmpMain -Algorithm MD5).Hash
        $verify[$name] = @{ bytes = $sz; md5 = $md5; ok = ($sz -eq $mainBytes -and $md5 -eq $mainMd5) }
        Write-Host "Verify $name : $sz bytes, MD5 $md5, match=$($verify[$name].ok)" -ForegroundColor $(if ($verify[$name].ok) { 'Green' } else { 'Red' })
    } else {
        $verify[$name] = @{ bytes = 0; md5 = ''; ok = $false }
        Write-Host "Verify $name : GAGAL download main.dart.js" -ForegroundColor Red
    }
}

Write-Host "`n=== Ringkasan verifikasi bundle ===" -ForegroundColor Cyan
$verify.GetEnumerator() | ForEach-Object {
    Write-Host "$($_.Key): $($_.Value.bytes) bytes, OK=$($_.Value.ok)"
}
$allMatch = ($verify.Values | Where-Object { -not $_.ok }).Count -eq 0
if (-not $allMatch) { throw 'Bundle tidak identik di semua subdomain' }
Write-Host 'Deploy ZIP selesai — bundle identik.' -ForegroundColor Green
