# Deploy parsial BFF Owner (Money Engine) — hanya owner_v2.php + lib owner.
# Gunakan ini jika diff terbatas pada endpoint pemilik; jangan pakai untuk perubahan marketplace/booking/payment global.
param(
    [switch]$Upload,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$apiRoot = Join-Path $root 'hosting\api.kakiempat.com'
$stageRoot = Join-Path $root 'build\deploy_api_owner'
$remoteBase = 'api.kakiempat.com'

$ownerFiles = @(
    @{ rel = 'owner_v2.php'; remote = "$remoteBase/owner_v2.php" },
    @{ rel = 'lib\kakiempat_owner_v2.php'; remote = "$remoteBase/lib/kakiempat_owner_v2.php" }
)

Write-Host '=== Deploy API Owner BFF (parsial) ===' -ForegroundColor Cyan
Write-Host 'File: owner_v2.php, lib/kakiempat_owner_v2.php'
Write-Host 'Jika juga berubah pet/booking/marketplace/payment -> deploy_api.ps1 + deploy_via_ftp -Target api' -ForegroundColor Yellow

if (Test-Path $stageRoot) { Remove-Item $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

$uploadList = @()
foreach ($f in $ownerFiles) {
    $src = Join-Path $apiRoot $f.rel
    if (-not (Test-Path $src)) { throw "Missing $src" }
    $dest = Join-Path $stageRoot $f.rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item $src $dest -Force
    $uploadList += @{ Local = $dest; Remote = $f.remote }
    Write-Host "  staged: $($f.rel)"
}

Write-Host "Paket lokal: $stageRoot"

if ($DryRun) {
    Write-Host 'DryRun — tidak upload.' -ForegroundColor DarkGray
    exit 0
}

if (-not $Upload) {
    Write-Host ''
    Write-Host 'Upload: .\scripts\deploy_api_owner.ps1 -Upload' -ForegroundColor Cyan
    Write-Host 'Atau API penuh: .\scripts\deploy_api.ps1; .\scripts\deploy_via_ftp.ps1 -Target api'
    exit 0
}

. (Join-Path $root 'scripts\lib\ftp_deploy.ps1')
$creds = Get-HostingFtpCredentials -ProjectRoot $root
Send-FtpFileList -Credentials $creds -Files $uploadList
Write-Host 'Deploy API Owner BFF selesai.' -ForegroundColor Green
