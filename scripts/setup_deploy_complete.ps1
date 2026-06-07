# Setup deploy Git->cPanel end-to-end (sekali jalan + verifikasi).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$gh = 'C:\Program Files\GitHub CLI\gh.exe'

Write-Host '=== Setup Deploy Kaki Empat v2 (no FTP) ===' -ForegroundColor Cyan

if (-not (Test-Path $gh)) {
    Write-Host 'Install GitHub CLI: winget install GitHub.cli' -ForegroundColor Yellow
}

$gitToken = $null
try {
    $cred = echo "protocol=https`nhost=github.com" | git credential fill 2>$null
    $gitToken = ($cred | Select-String '^password=').ToString().Replace('password=','')
} catch { }

if ($gitToken -and (Test-Path $gh)) {
    $env:GH_TOKEN = $gitToken
    & $gh secret set REPO_CLONE_TOKEN --repo kanzapro/kakiempat_v2 --body $gitToken 2>$null
    & $gh secret set CPANEL_REPO_PATH --repo kanzapro/kakiempat_v2 --body '/home/kakiempa/repo_kakiempat' 2>$null
    Write-Host 'GitHub secrets: REPO_CLONE_TOKEN, CPANEL_REPO_PATH' -ForegroundColor Green
}

Write-Host 'Build artefak deploy...' -ForegroundColor Cyan
& (Join-Path $root 'scripts\deploy_git.ps1') -Layer all -WebRenderer html -SkipAnalyze

Write-Host ''
Write-Host 'Push ke GitHub (Actions akan provision + pull cPanel)...' -ForegroundColor Yellow
Set-Location $root
git add .github/workflows/deploy.yml scripts/ci/provision_cpanel_git.sh scripts/deploy_git.ps1 build/deploy build/deploy_api
git status --short

if ((git status --porcelain) -match '^(M|A|\?\?)') {
    git commit -m "deploy: artefak build + perbaikan workflow cPanel git pull"
    git push origin main
    if (Test-Path $gh) {
        $env:GH_TOKEN = $gitToken
        Start-Sleep -Seconds 5
        & $gh run list --repo kanzapro/kakiempat_v2 --limit 1
    }
} else {
    Write-Host 'Tidak ada perubahan untuk commit.' -ForegroundColor DarkGray
}

Write-Host 'Selesai.' -ForegroundColor Green
