# Build + paket artefak deploy untuk git push -> cPanel git pull (.cpanel.yml).
# FTP/SFTP diblokir — tidak ada upload langsung ke server.
param(
    [ValidateSet('all', 'api', 'web')]
    [string]$Layer = 'all',
    [ValidateSet('owner', 'sitter', 'admin', 'staging', 'www')]
    [string]$Target = 'owner',
    [ValidateSet('html', 'canvaskit', 'skwasm')]
    [string]$WebRenderer = 'html',
    [switch]$SkipAnalyze,
    [switch]$SkipBuild,
    [switch]$TriggerCpanel
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

Write-Host '=== Deploy Git (no FTP) ===' -ForegroundColor Cyan
Write-Host 'Alur: build lokal -> git commit artefak -> git push -> GitHub Actions -> cPanel pull' -ForegroundColor DarkGray

if ($Layer -in @('api', 'all')) {
    & (Join-Path $root 'scripts\deploy_api.ps1')
}

if ($Layer -in @('web', 'all')) {
    $webScript = Join-Path $root 'scripts\deploy_web.ps1'
    $params = @{
        WebRenderer = $WebRenderer
        NoZip       = $true
    }
    if ($SkipAnalyze) { $params.SkipAnalyze = $true }
    if ($SkipBuild) { $params.SkipBuild = $true }
    if ($Layer -eq 'all') {
        $params.All = $true
    } else {
        $params.Target = $Target
    }
    & $webScript @params
}

Write-Host ''
Write-Host 'Artefak siap di:' -ForegroundColor Green
Write-Host '  build/deploy_api/          -> api.kakiempat.com/'
Write-Host '  build/deploy/<target>/web/ -> docroot subdomain'
Write-Host ''
Write-Host 'Langkah berikutnya:' -ForegroundColor Yellow
Write-Host '  git add build/deploy_api build/deploy'
Write-Host '  git commit -m "deploy: <deskripsi>"'
Write-Host '  git push origin main'
Write-Host ''
Write-Host 'GitHub Actions akan memicu cPanel VersionControl/update (secret CPANEL_API_TOKEN).'

if ($TriggerCpanel) {
    & (Join-Path $root 'scripts\trigger_cpanel_deploy.ps1')
}
