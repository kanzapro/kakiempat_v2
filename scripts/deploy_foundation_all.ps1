# Build + paket fondasi v2 (API + web semua subdomain) untuk git push.
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
    & (Join-Path $root 'scripts\deploy_web.ps1') -All -WebRenderer html -NoZip
}

Write-Host '`n=== 3. Git push (no FTP) ===' -ForegroundColor Cyan
Write-Host '  git add build/deploy build/deploy_api hosting/'
Write-Host '  git commit -m "deploy: fondasi v2"'
Write-Host '  git push origin main'

if (-not $SkipMigration -and -not $SkipApi) {
    Write-Host "`n=== 4. Migrasi $MigrationFile ===" -ForegroundColor Cyan
    & (Join-Path $root 'scripts\run_v2_migration.ps1') -File $MigrationFile
}

Write-Host '`n=== 5. Smoke test ===' -ForegroundColor Cyan
& (Join-Path $root 'scripts\test_v2_foundation.ps1')

Write-Host '`nDeploy fondasi selesai. GitHub Actions memicu cPanel pull.' -ForegroundColor Green
