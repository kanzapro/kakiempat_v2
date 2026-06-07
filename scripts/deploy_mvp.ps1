# Deploy MVP: API penuh + web owner & sitter (git -> cPanel).
param(
    [ValidateSet('html', 'canvaskit', 'skwasm')]
    [string]$WebRenderer = 'html',
    [switch]$SkipAnalyze,
    [switch]$Push,
    [switch]$TriggerCpanel
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host '=== Deploy MVP (owner + sitter + API) ===' -ForegroundColor Cyan

& (Join-Path $root 'scripts\deploy_api.ps1')

$webScript = Join-Path $root 'scripts\deploy_web.ps1'

function Invoke-WebDeploy([string]$targetName, [switch]$SkipBuildStep) {
    $params = @{
        Target      = $targetName
        WebRenderer = $WebRenderer
        NoZip       = $true
    }
    if ($SkipAnalyze) { $params.SkipAnalyze = $true }
    if ($SkipBuildStep) { $params.SkipBuild = $true }
    & $webScript @params
}

Invoke-WebDeploy -targetName owner
Invoke-WebDeploy -targetName sitter -SkipBuildStep

Write-Host ''
Write-Host 'Artefak:' -ForegroundColor Green
Write-Host '  build/deploy_api/'
Write-Host '  build/deploy/owner/web/'
Write-Host '  build/deploy/sitter/web/'

if (-not $Push) {
    Write-Host ''
    Write-Host 'Push: .\scripts\deploy_mvp.ps1 -Push [-TriggerCpanel]' -ForegroundColor Yellow
    exit 0
}

git add build/deploy_api build/deploy/owner build/deploy/sitter
$status = git status --porcelain build/deploy_api build/deploy/owner build/deploy/sitter 2>$null
if (-not $status) {
    Write-Host 'Tidak ada perubahan artefak untuk commit.' -ForegroundColor DarkGray
} else {
    git commit -m "deploy: MVP owner+sitter web + API v2 artefak"
    git push origin main
    Write-Host 'Git push selesai.' -ForegroundColor Green
}

if ($TriggerCpanel) {
    & (Join-Path $root 'scripts\trigger_cpanel_deploy.ps1')
}
