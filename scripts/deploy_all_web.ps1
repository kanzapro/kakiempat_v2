# Build satu Flutter web + ZIP per subdomain (upload manual / File Manager).
# Disarankan: .\scripts\deploy_web.ps1 -All (manifest + output terstruktur).
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host 'deploy_all_web.ps1 — delegasi ke deploy_web.ps1 -All' -ForegroundColor Yellow
& (Join-Path $root 'scripts\deploy_web.ps1') -All @PSBoundParameters
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
