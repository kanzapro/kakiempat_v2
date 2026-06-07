# Deploy build/web ke subdomain via cPanel UAPI (per-file upload).
param(
    [ValidateSet('owner', 'sitter', 'admin', 'staging', 'www', 'all')]
    [string]$Target = 'all',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
. (Join-Path $root 'scripts\lib\web_seo.ps1')

$map = @{
    owner   = 'owner.kakiempat.com'
    sitter  = 'sitter.kakiempat.com'
    admin   = 'admin.kakiempat.com'
    staging = 'staging.kakiempat.com'
    www     = 'public_html'
}

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
if (-not (Test-Path $credPath)) { throw "Missing $credPath" }
$ini = Get-Content $credPath -Raw
$user = Get-IniValue $ini 'cpanel' 'username'
$pass = Get-IniValue $ini 'cpanel' 'password'
if (-not $user -or -not $pass) { throw 'cpanel credentials required' }

if (-not $SkipBuild) {
    Write-Host 'flutter build web --release ...'
    flutter build web --release --dart-define=API_BASE_URL=https://api.kakiempat.com
    if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }
}

$webRoot = Join-Path $root 'build\web'
if (-not (Test-Path $webRoot)) { throw "Missing $webRoot" }

$targets = if ($Target -eq 'all') { @('owner', 'sitter', 'admin', 'staging', 'www') } else { @($Target) }

foreach ($t in $targets) {
    $targetWebRoot = New-TargetWebRoot `
        -SourceDir $webRoot `
        -Target $t `
        -ProjectRoot $root `
        -StagingDir (Join-Path $root "build\deploy_staging\$t")
    $files = Get-ChildItem -Path $targetWebRoot -Recurse -File
    $remoteBase = "/home/kakiempa/$($map[$t])"
    Write-Host ">> Deploy $t ($($files.Count) files) -> $remoteBase"
    $ok = 0; $fail = 0
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($targetWebRoot.Length).TrimStart('\').Replace('\', '/')
        $dir = if ($rel.Contains('/')) { "$remoteBase/" + (Split-Path $rel -Parent).Replace('\', '/') } else { $remoteBase }
        $out = curl.exe -sS -u "${user}:${pass}" `
            -H 'Accept: application/json' `
            "https://kakiempat.com:2083/execute/Fileman/save_file_content" `
            --data-urlencode "dir=$dir" `
            --data-urlencode "file=$($f.Name)" `
            --data-urlencode "content@$($f.FullName)" 2>&1
        if ($out -match '"status":1') { $ok++ } else { $fail++; Write-Host "FAIL $rel : $out" }
    }
    Write-Host "   $t done: $ok ok, $fail fail"
}

Write-Host 'Deploy selesai.' -ForegroundColor Green
