# Picu git pull + .cpanel.yml di server via cPanel VersionControl API (tanpa FTP).
param(
    [string]$RepoPath = '/home/kakiempa/repo_kakiempat',
    [string]$Branch = 'main',
    [string]$CpanelHost = 'kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

$token = $env:CPANEL_API_TOKEN
$user = 'kakiempa'
if (Test-Path $credPath) {
    $ini = Get-Content $credPath -Raw
    $user = Get-IniValue $ini 'cpanel' 'username'
    if (-not $token) { $token = Get-IniValue $ini 'cpanel' 'api_token' }
}
if (-not $token) {
    throw 'CPANEL_API_TOKEN tidak ditemukan. Set env CPANEL_API_TOKEN atau cpanel.api_token di hosting.credentials'
}

$encodedRepo = [uri]::EscapeDataString($RepoPath)
$encodedBranch = [uri]::EscapeDataString($Branch)
$url = "https://${CpanelHost}:2083/execute/VersionControl/update?repository_root=${encodedRepo}&branch=${encodedBranch}"

Write-Host "Memicu cPanel deploy: $RepoPath (branch=$Branch)" -ForegroundColor Cyan
$out = curl.exe -sS -w "`nHTTP:%{http_code}" `
    -H "Authorization: cpanel ${user}:${token}" `
    -H 'Accept: application/json' `
    $url
Write-Host $out

if ($out -notmatch 'HTTP:200' -or $out -notmatch '"status":1') {
    throw 'cPanel VersionControl/update gagal — cek token dan path repo di cPanel Git Version Control'
}
Write-Host 'OK — cPanel akan git pull lalu menjalankan .cpanel.yml' -ForegroundColor Green
