# Money Engine — deploy owner subdomain (web) + BFF owner (API parsial) via skrip otomatis.
param(
    [ValidateSet('web', 'api', 'both')]
    [string]$Layer = 'both',
    [ValidateSet('html', 'canvaskit', 'skwasm')]
    [string]$WebRenderer = 'html',
    [switch]$Upload,
    [switch]$SkipAnalyze,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host '=== Owner Money Engine deploy ===' -ForegroundColor Cyan

if ($Layer -in @('api', 'both')) {
    $apiArgs = @('-Upload')
    if (-not $Upload) { $apiArgs = @() }
    & (Join-Path $root 'scripts\deploy_api_owner.ps1') @apiArgs
}

if ($Layer -in @('web', 'both')) {
    $webArgs = @(
        '-Target', 'owner',
        '-WebRenderer', $WebRenderer
    )
    if ($SkipAnalyze) { $webArgs += '-SkipAnalyze' }
    if ($SkipBuild) { $webArgs += '-SkipBuild' }
    if ($Upload) { $webArgs += '-Upload' }
    & (Join-Path $root 'scripts\deploy_web.ps1') @webArgs
}

Write-Host 'Selesai.' -ForegroundColor Green
