# Buat repo GitHub (jika belum ada) dan push branch main.
# Prasyarat: gh auth login (sekali) + CPANEL_API_TOKEN di GitHub Secrets.
param(
    [string]$RepoName = 'kakiempat_v2',
    [ValidateSet('public', 'private')]
    [string]$Visibility = 'private'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw 'GitHub CLI (gh) belum terpasang. Install: winget install GitHub.cli'
}

gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Login GitHub (device flow)...' -ForegroundColor Yellow
    gh auth login --hostname github.com --git-protocol https --web --skip-ssh-key
}

$owner = (gh api user -q .login 2>$null).Trim()
if (-not $owner) { throw 'Tidak bisa membaca username GitHub setelah login.' }

$remoteUrl = "https://github.com/$owner/$RepoName.git"
Write-Host "Target: $remoteUrl ($Visibility)" -ForegroundColor Cyan

$exists = gh repo view "$owner/$RepoName" 2>$null
if ($LASTEXITCODE -ne 0) {
    gh repo create $RepoName --$Visibility --source . --remote origin --description 'Kaki Empat v2 - Flutter web + PHP API'
    if ($LASTEXITCODE -ne 0) { throw 'gh repo create gagal' }
} else {
    $current = git remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) {
        git remote add origin $remoteUrl
    } elseif ($current -ne $remoteUrl) {
        git remote set-url origin $remoteUrl
    }
}

git push -u origin main
Write-Host 'Push selesai. Cek Actions di GitHub untuk workflow deploy.' -ForegroundColor Green
Write-Host "https://github.com/$owner/$RepoName/actions" -ForegroundColor Cyan
