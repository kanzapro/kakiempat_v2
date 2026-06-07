# Upload build/release_v2 ZIP + API ke cPanel via FTP (butuh hosting.credentials).
param(
    [ValidateSet('web', 'api', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$releaseDir = Join-Path $root 'build\release_v2'
if ($Target -in @('web', 'all')) {
    foreach ($z in @('www-deploy.zip', 'owner-deploy.zip', 'sitter-deploy.zip', 'admin-deploy.zip')) {
        if (-not (Test-Path (Join-Path $releaseDir $z))) {
            throw "Jalankan scripts/build_release_v2.ps1 dulu — missing $z"
        }
    }
}

if ($Target -eq 'api') {
    & (Join-Path $root 'scripts\deploy_via_ftp.ps1') -Target api
} elseif ($Target -eq 'web') {
    & (Join-Path $root 'scripts\deploy_via_ftp.ps1') -Target all
} else {
    & (Join-Path $root 'scripts\deploy_api.ps1')
    & (Join-Path $root 'scripts\deploy_via_ftp.ps1') -Target api
    Write-Host 'Upload ZIP manual: ekstrak isi build/release_v2/*.zip ke docroot subdomain.'
    Write-Host 'Atau: scripts/deploy_web_cpanel.ps1 -SkipBuild (setelah build_release_v2.ps1)'
}
