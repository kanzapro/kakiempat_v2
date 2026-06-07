# Paket parsial BFF Owner (Money Engine) — staging lokal untuk git push.
# Gunakan ini jika diff terbatas pada endpoint pemilik; untuk perubahan global gunakan deploy_api.ps1.
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$apiRoot = Join-Path $root 'hosting\api.kakiempat.com'
$stageRoot = Join-Path $root 'build\deploy_api_owner'

$ownerFiles = @(
    'owner_v2.php',
    'lib\kakiempat_owner_v2.php'
)

Write-Host '=== Deploy API Owner BFF (parsial, git push) ===' -ForegroundColor Cyan
Write-Host 'File: owner_v2.php, lib/kakiempat_owner_v2.php'
Write-Host 'Perubahan global API -> deploy_api.ps1 + commit hosting/api.kakiempat.com/**' -ForegroundColor Yellow

if (Test-Path $stageRoot) { Remove-Item $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

foreach ($rel in $ownerFiles) {
    $src = Join-Path $apiRoot $rel
    if (-not (Test-Path $src)) { throw "Missing $src" }
    $dest = Join-Path $stageRoot $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
    Copy-Item $src $dest -Force
    Write-Host "  staged: $rel"
}

Write-Host "Paket lokal: $stageRoot"

if ($DryRun) {
    Write-Host 'DryRun — tidak ada langkah lanjut.' -ForegroundColor DarkGray
    exit 0
}

Write-Host ''
Write-Host 'Langkah deploy:' -ForegroundColor Cyan
Write-Host '  1. Commit hosting/api.kakiempat.com/owner_v2.php (+ lib) ATAU build/deploy_api_owner/'
Write-Host '  2. .\scripts\deploy_git.ps1 -Layer api   # jika perlu refresh build/deploy_api penuh'
Write-Host '  3. git push origin main'
