# Upload owner-deploy.zip + extract script ke owner.kakiempat.com, ekstrak ke docroot.
param(
    [string]$ZipPath = '',
    [switch]$SkipUpload
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'scripts\lib\cpanel_upload.ps1')

if (-not $ZipPath) {
    $ZipPath = Join-Path $root 'build\release_v2\owner-deploy.zip'
}
$extractPhp = Join-Path $root 'build\deploy-owner-extract.php'
$ownerDocroot = '/home/kakiempa/owner.kakiempat.com'

if (-not (Test-Path $ZipPath)) {
    throw "ZIP tidak ada: $ZipPath - jalankan build_release_v2.ps1 atau buat dari build/deploy/owner/web"
}
if (-not (Test-Path $extractPhp)) {
    throw "Extract script tidak ada: $extractPhp"
}

$creds = Get-HostingCpanelCredentials -ProjectRoot $root

if (-not $SkipUpload) {
    $zipMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Host "Upload owner-deploy.zip (${zipMb} MB) -> $ownerDocroot ..." -ForegroundColor Cyan
    Send-CpanelFile -Credentials $creds -LocalPath $ZipPath -RemoteDir $ownerDocroot -RemoteFile 'owner-deploy.zip' -MaxRetry 8 | Out-Null
    Write-Host '[OK] owner-deploy.zip'

    Write-Host 'Upload deploy-owner-extract.php ...' -ForegroundColor Cyan
    Send-CpanelFile -Credentials $creds -LocalPath $extractPhp -RemoteDir $ownerDocroot -RemoteFile 'deploy-owner-extract.php' | Out-Null
    Write-Host '[OK] deploy-owner-extract.php'
}

Write-Host 'Trigger server-side extract ...' -ForegroundColor Cyan
$u = 'https://owner.kakiempat.com/deploy-owner-extract.php?run=1'
$out = curl.exe -sS -L --connect-timeout 300 --max-time 600 -H 'Accept: text/plain' $u 2>&1
Write-Host $out
if ($out -notmatch 'OK owner deploy') {
    throw 'Extract gagal - cek output di atas'
}

Write-Host 'Verifikasi HTTP ...' -ForegroundColor Cyan
$idx = curl.exe -sS -o NUL -w '%{http_code}' 'https://owner.kakiempat.com/index.html'
$main = curl.exe -sS -o NUL -w '%{http_code}' 'https://owner.kakiempat.com/main.dart.js'
Write-Host "  index.html HTTP $idx"
Write-Host "  main.dart.js HTTP $main"
if ($idx -ne '200' -or $main -ne '200') {
    throw 'File utama tidak dapat diakses via HTTPS'
}

$html = curl.exe -sS 'https://owner.kakiempat.com/index.html' 2>&1
if ($html -notmatch '<base href="/">') {
    throw 'base href di index.html bukan /'
}
Write-Host '  base href: OK (/)'

Write-Host 'Deploy Owner selesai.' -ForegroundColor Green
