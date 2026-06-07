# Build + deploy fondasi v2 (API + web semua subdomain).
# Butuh: .cursor/secrets/hosting.credentials + FTP port 21 tidak diblokir.
param(
    [switch]$SkipWeb,
    [switch]$SkipApi,
    [switch]$SkipMigration,
    [string]$MigrationFile = '010_profiles_pets_catalog_booking.sql'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host '=== 1. Paket API ===' -ForegroundColor Cyan
if (-not $SkipApi) {
    & (Join-Path $root 'scripts\deploy_api.ps1')
}

Write-Host '`n=== 2. Build Flutter web ===' -ForegroundColor Cyan
if (-not $SkipWeb) {
    flutter build web --release --dart-define=API_BASE_URL=https://www.api.kakiempat.com
}

Write-Host '`n=== 3. FTP upload ===' -ForegroundColor Cyan
if (-not $SkipApi) {
    & (Join-Path $root 'scripts\deploy_via_ftp.ps1') -Target api
}
if (-not $SkipWeb) {
    & (Join-Path $root 'scripts\deploy_web_fast.ps1') -Target all
}

if (-not $SkipMigration -and -not $SkipApi) {
    Write-Host "`n=== 4. Migrasi $MigrationFile ===" -ForegroundColor Cyan
    & (Join-Path $root 'scripts\run_v2_migration.ps1') -File $MigrationFile
}

Write-Host '`n=== 5. Smoke test ===' -ForegroundColor Cyan
& (Join-Path $root 'scripts\test_v2_foundation.ps1')

Write-Host '`nDeploy fondasi selesai.' -ForegroundColor Green
Write-Host 'Jika FTP/Imunify360 gagal: whitelist IP di cPanel, lalu ulangi langkah 3-4.'
