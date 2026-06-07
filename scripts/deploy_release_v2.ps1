# Paket release v2 untuk git push (menggantikan upload FTP).
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
    & (Join-Path $root 'scripts\deploy_git.ps1') -Layer api
} elseif ($Target -eq 'web') {
    & (Join-Path $root 'scripts\deploy_git.ps1') -Layer all -WebRenderer html
} else {
    & (Join-Path $root 'scripts\deploy_git.ps1') -Layer all -WebRenderer html
    Write-Host 'ZIP release_v2 tetap tersedia untuk arsip; deploy produksi via build/deploy + git push.'
}
