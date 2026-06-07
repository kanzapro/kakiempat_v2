# Pra-live: SSL wildcard + keamanan database bersama.
param(
    [string]$ApiBase = 'https://api.kakiempat.com',
    [int]$TimeoutSec = 15,
    [switch]$LocalOnly
)

$ErrorActionPreference = 'Stop'
$here = $MyInvocation.MyCommand.Path
$root = Split-Path -Parent (Split-Path -Parent $here)

Write-Host '=== Verifikasi SSL (domain utama + subdomain) ===' -ForegroundColor Cyan
if (-not $LocalOnly) {
    & (Join-Path $root 'scripts\verify_ssl_v2.ps1') -TimeoutSec $TimeoutSec
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} else {
    Write-Host 'Lewati SSL remote (-LocalOnly)' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=== Verifikasi keamanan database ===' -ForegroundColor Cyan
$dbArgs = @{ ApiBase = $ApiBase; TimeoutSec = $TimeoutSec }
if ($LocalOnly) { $dbArgs.LocalOnly = $true }
& (Join-Path $root 'scripts\verify_db_security_v2.ps1') @dbArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $LocalOnly) {
    Write-Host ''
    Write-Host '=== Verifikasi rilis (CORS, health, stack) ===' -ForegroundColor Cyan
    & (Join-Path $root 'scripts\verify_release_v2.ps1') -ApiBase $ApiBase
    exit $LASTEXITCODE
}

Write-Host 'Pengecekan lokal infrastruktur OK (jalankan tanpa -LocalOnly setelah deploy)' -ForegroundColor Green
