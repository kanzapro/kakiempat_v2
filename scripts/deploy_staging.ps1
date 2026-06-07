# Build & paket Flutter web untuk staging.kakiempat.com (QA terisolasi).
param(
    [switch]$SkipBuild,
    [switch]$SkipAnalyze,
    [string]$ApiBaseUrl = 'https://www.api.kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$defines = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    '--dart-define=CPANEL_MYSQL_HOST=localhost',
    '--dart-define=CPANEL_MYSQL_DATABASE=kakiempa_v2',
    '--dart-define=CPANEL_MYSQL_USER=kakiempa_v2_user'
)

Write-Host '=== Staging deploy — staging.kakiempat.com ===' -ForegroundColor Cyan
Write-Host "API: $ApiBaseUrl"
Write-Host 'Host staging memakai OwnerShell (AuthGate) — uji alur owner sebelum production.'

if (-not $SkipAnalyze) {
    Write-Host 'flutter analyze ...'
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze gagal' }
}

if (-not $SkipBuild) {
    Write-Host 'flutter build web --release ...'
    flutter build web --release --tree-shake-icons @defines
    if ($LASTEXITCODE -ne 0) { throw 'flutter build web gagal' }
}

$webRoot = Join-Path $root 'build\web'
if (-not (Test-Path $webRoot)) { throw "Tidak ada $webRoot" }

$outDir = Join-Path $root 'build\staging'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$zipPath = Join-Path $outDir 'staging-deploy.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $webRoot '*') -DestinationPath $zipPath -Force

$manifest = @{
    target = 'staging'
    url = 'https://staging.kakiempat.com'
    api_base_url = $ApiBaseUrl
    built_at = (Get-Date).ToUniversalTime().ToString('o')
    zip = $zipPath
    docroot = 'staging.kakiempat.com'
    notes = 'Sama binary dengan owner; hostname staging → OwnerShell via domain_router.dart'
}
$manifestPath = Join-Path $outDir 'staging_manifest.json'
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host ''
Write-Host 'Staging siap:' -ForegroundColor Green
Write-Host "  ZIP:      $zipPath"
Write-Host "  Manifest: $manifestPath"
Write-Host '  Upload:   ekstrak isi ZIP ke docroot staging.kakiempat.com'
Write-Host ''
Write-Host 'Rutin QA: jalankan script ini setelah merge fitur Fase 1–2, lalu upload ke staging.'
