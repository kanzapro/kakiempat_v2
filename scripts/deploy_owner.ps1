# Money Engine — build owner web + paket BFF owner untuk git push -> cPanel.
param(
    [ValidateSet('web', 'api', 'both')]
    [string]$Layer = 'both',
    [ValidateSet('html', 'canvaskit', 'skwasm')]
    [string]$WebRenderer = 'html',
    [switch]$SkipAnalyze,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host '=== Owner Money Engine deploy (git push) ===' -ForegroundColor Cyan

if ($Layer -in @('api', 'both')) {
    & (Join-Path $root 'scripts\deploy_api_owner.ps1')
}

if ($Layer -in @('web', 'both')) {
    $webArgs = @(
        '-Target', 'owner',
        '-WebRenderer', $WebRenderer,
        '-NoZip'
    )
    if ($SkipAnalyze) { $webArgs += '-SkipAnalyze' }
    if ($SkipBuild) { $webArgs += '-SkipBuild' }
    & (Join-Path $root 'scripts\deploy_web.ps1') @webArgs
}

Write-Host ''
Write-Host 'Commit + push artefak, lalu GitHub Actions memicu cPanel deploy.' -ForegroundColor Yellow
Write-Host '  git add build/deploy/owner build/deploy_api_owner hosting/api.kakiempat.com/owner_v2.php'
Write-Host '  git push origin main'
