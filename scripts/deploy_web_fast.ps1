# FTP cepat: upload build/web ke subdomain (tanpa MKD per file).
param(
    [ValidateSet('www', 'owner', 'sitter', 'admin', 'staging', 'all')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'scripts\lib\web_seo.ps1')
$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
$webSrc = Join-Path $root 'build\web'
if (-not (Test-Path $webSrc)) { throw "Jalankan: flutter build web --release" }

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

$ini = Get-Content $credPath -Raw
$user = Get-IniValue $ini 'cpanel' 'username'
$pass = Get-IniValue $ini 'cpanel' 'password'
$ftpHost = 'ftp.kakiempat.com'
$map = @{ www = 'public_html'; owner = 'owner.kakiempat.com'; sitter = 'sitter.kakiempat.com'; admin = 'admin.kakiempat.com'; staging = 'staging.kakiempat.com' }
$targets = if ($Target -eq 'all') { @('www', 'owner', 'sitter', 'admin', 'staging') } else { @($Target) }

foreach ($t in $targets) {
    $base = $map[$t]
    $targetWebRoot = New-TargetWebRoot `
        -SourceDir $webSrc `
        -Target $t `
        -ProjectRoot $root `
        -StagingDir (Join-Path $root "build\deploy_staging\$t")
    $files = Get-ChildItem $targetWebRoot -Recurse -File
    Write-Host ">> $t ($base) $($files.Count) files"
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($targetWebRoot.Length).TrimStart('\').Replace('\', '/')
        $remote = "$base/$rel"
        $null = curl.exe -sS --connect-timeout 60 --ftp-create-dirs --ftp-pasv `
            -u "${user}:${pass}" -T $f.FullName "ftp://${ftpHost}/${remote}" 2>&1
    }
    Write-Host "OK $t"
}
