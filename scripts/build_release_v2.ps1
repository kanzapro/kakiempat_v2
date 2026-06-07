# Build production Kaki Empat v2 — Flutter web + ZIP per subdomain.
param(
    [switch]$SkipClean,
    [switch]$SkipAnalyze,
    [string]$ApiBaseUrl = 'https://www.api.kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
. (Join-Path $root 'scripts\lib\web_seo.ps1')

$defines = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    '--dart-define=CPANEL_MYSQL_HOST=localhost',
    '--dart-define=CPANEL_MYSQL_DATABASE=kakiempa_v2',
    '--dart-define=CPANEL_MYSQL_USER=kakiempa_v2_user'
)

$zipTargets = @{
    www     = 'www-deploy.zip'
    owner   = 'owner-deploy.zip'
    sitter  = 'sitter-deploy.zip'
    admin   = 'admin-deploy.zip'
    staging = 'staging-deploy.zip'
}

Write-Host '=== Kaki Empat v2 — Release Build ===' -ForegroundColor Cyan

if (-not $SkipClean) {
    Write-Host 'flutter clean ...'
    flutter clean
}

Write-Host 'flutter pub get ...'
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal' }

if (-not $SkipAnalyze) {
    Write-Host 'flutter analyze ...'
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze gagal' }
}

Write-Host 'flutter build web --release --no-tree-shake-icons ...'
flutter build web --release --no-tree-shake-icons @defines
if ($LASTEXITCODE -ne 0) { throw 'flutter build web gagal' }

$webRoot = Join-Path $root 'build\web'
if (-not (Test-Path $webRoot)) { throw "Tidak ada $webRoot" }

$mainJs = Join-Path $webRoot 'main.dart.js'
$mainJsSize = if (Test-Path $mainJs) { (Get-Item $mainJs).Length } else { 0 }

$releaseDir = Join-Path $root 'build\release_v2'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$zips = @{}
foreach ($entry in $zipTargets.GetEnumerator()) {
    $zipPath = Join-Path $releaseDir $entry.Value
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    $targetWebRoot = New-TargetWebRoot `
        -SourceDir $webRoot `
        -Target $entry.Key `
        -ProjectRoot $root `
        -StagingDir (Join-Path $releaseDir "staging\$($entry.Key)")
    Compress-Archive -Path (Join-Path $targetWebRoot '*') -DestinationPath $zipPath -Force
    $zips[$entry.Key] = @{
        file = $entry.Value
        bytes = (Get-Item $zipPath).Length
        mb = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    }
    Write-Host "ZIP $($entry.Key): $zipPath ($($zips[$entry.Key].mb) MB)"
}

# Paket API (tanpa secret)
Write-Host 'scripts/deploy_api.ps1 ...'
& (Join-Path $root 'scripts\deploy_api.ps1')

$manifest = @{
    version = '2.0.0'
    built_at = (Get-Date).ToUniversalTime().ToString('o')
    api_base_url = $ApiBaseUrl
    flutter = (flutter --version 2>$null | Select-Object -First 1)
    main_dart_js_bytes = $mainJsSize
    main_dart_js_mb = [math]::Round($mainJsSize / 1MB, 2)
    web_root = $webRoot
    api_package = (Join-Path $root 'build\deploy_api')
    zips = $zips
    docroots = @{
        www     = 'public_html (www.kakiempat.com)'
        owner   = 'owner.kakiempat.com'
        sitter  = 'sitter.kakiempat.com'
        admin   = 'admin.kakiempat.com'
        staging = 'staging.kakiempat.com'
    }
}

$manifestPath = Join-Path $releaseDir 'release_manifest.json'
$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host ''
Write-Host 'Release siap:' -ForegroundColor Green
Write-Host "  Web:    $webRoot"
Write-Host "  ZIP:    $releaseDir"
Write-Host "  API:    build\deploy_api"
Write-Host "  Manifest: $manifestPath"
Write-Host "  main.dart.js: $($manifest.main_dart_js_mb) MB (release minified)"
