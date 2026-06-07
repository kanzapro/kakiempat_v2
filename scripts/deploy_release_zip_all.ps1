# DEPRECATED — FTP diblokir. Gunakan deploy_git.ps1 + git push.
param(
    [string]$ZipName = 'www-deploy.zip'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host 'deploy_release_zip_all.ps1 tidak lagi memakai FTP.' -ForegroundColor Yellow
Write-Host "ZIP $ZipName diabaikan — memakai deploy_git.ps1 ..." -ForegroundColor DarkGray
& (Join-Path $root 'scripts\deploy_git.ps1') -Layer all -WebRenderer html
Write-Host 'Lanjut: git add build/deploy build/deploy_api && git commit && git push origin main'
