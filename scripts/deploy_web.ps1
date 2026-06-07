# Deploy Flutter web per subdomain — Money Engine First (owner prioritas).
# Build sekali, paket terpisah per target (ZIP + manifest) untuk upload independen.
param(
    [ValidateSet('owner', 'sitter', 'admin', 'staging', 'www')]
    [string]$Target = 'owner',
    [ValidateSet('html', 'canvaskit', 'skwasm')]
    [string]$WebRenderer = 'html',
    [switch]$All,
    [switch]$SkipBuild,
    [switch]$SkipAnalyze,
    [switch]$Upload,
    [switch]$NoZip,
    [string]$ApiBaseUrl = 'https://www.api.kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
. (Join-Path $root 'scripts\lib\web_seo.ps1')
. (Join-Path $root 'scripts\lib\winscp_sync.ps1')
$scriptLib = Join-Path $root 'scripts\lib'

$targets = [ordered]@{
    owner   = @{ docroot = 'owner.kakiempat.com';   url = 'https://owner.kakiempat.com';   zip = 'owner-deploy.zip' }
    sitter  = @{ docroot = 'sitter.kakiempat.com';  url = 'https://sitter.kakiempat.com';  zip = 'sitter-deploy.zip' }
    admin   = @{ docroot = 'admin.kakiempat.com';   url = 'https://admin.kakiempat.com';   zip = 'admin-deploy.zip' }
    staging = @{ docroot = 'staging.kakiempat.com'; url = 'https://staging.kakiempat.com'; zip = 'staging-deploy.zip' }
    www     = @{ docroot = 'public_html';           url = 'https://www.kakiempat.com';     zip = 'www-deploy.zip' }
}

$defines = @(
    "--dart-define=API_BASE_URL=$ApiBaseUrl",
    '--dart-define=CPANEL_MYSQL_HOST=localhost',
    '--dart-define=CPANEL_MYSQL_DATABASE=kakiempa_v2',
    '--dart-define=CPANEL_MYSQL_USER=kakiempa_v2_user'
)

function Get-GitShortHash {
    try {
        $h = git -C $root rev-parse --short HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $h) { return $h.Trim() }
    } catch { }
    return 'unknown'
}

function New-DeployPackage([string]$name, [hashtable]$meta, [string]$webRoot, [string]$webRenderer = 'html') {
    $deployRoot = Join-Path $root "build\deploy\$name"
    New-Item -ItemType Directory -Force -Path $deployRoot | Out-Null

    $targetWebRoot = New-TargetWebRoot `
        -SourceDir $webRoot `
        -Target $name `
        -ProjectRoot $root `
        -StagingDir (Join-Path $deployRoot 'web')

    if ($webRenderer -eq 'html') {
        $canvasDir = Join-Path $targetWebRoot 'canvaskit'
        if (Test-Path $canvasDir) {
            Remove-Item $canvasDir -Recurse -Force
            Write-Host "    Trim: canvaskit/ dihapus (renderer html, CDN runtime)" -ForegroundColor DarkGray
        }
    }

    if (-not $NoZip) {
        $zipPath = Join-Path $deployRoot $meta.zip
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        Compress-Archive -Path (Join-Path $targetWebRoot '*') -DestinationPath $zipPath -Force
    }

    $manifest = [ordered]@{
        target       = $name
        url          = $meta.url
        docroot      = $meta.docroot
        api_base_url = $ApiBaseUrl
        built_at     = (Get-Date).ToUniversalTime().ToString('o')
        git          = Get-GitShortHash
        web_renderer = $webRenderer
        zip          = if ($NoZip) { $null } else { (Join-Path $deployRoot $meta.zip) }
        notes        = 'Routing subdomain via domain_router.dart (hostname runtime).'
    }
    $manifestPath = Join-Path $deployRoot "$name`_manifest.json"
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8

    Write-Host "  $name -> $deployRoot" -ForegroundColor Green
    if (-not $NoZip) { Write-Host "    ZIP: $zipPath" }
    Write-Host "    Manifest: $manifestPath"

    return @{ deployRoot = $deployRoot; webRoot = $targetWebRoot }
}

function Invoke-WinScpUpload([string]$name, [string]$webRoot) {
    $credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
    if (-not (Test-Path $credPath)) {
        throw "Upload membutuhkan $credPath - salin dari hosting.credentials.example"
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
    $ini = Get-Content $credPath -Raw
    $user = Get-IniValue $ini 'cpanel' 'username'
    $pass = Get-IniValue $ini 'cpanel' 'password'
    $primary = Get-IniValue $ini 'cpanel' 'primary_domain'
    $sharedIp = Get-IniValue $ini 'cpanel' 'shared_ip'
    if (-not $user -or -not $pass) { throw 'cpanel.username / cpanel.password tidak ditemukan di hosting.credentials' }

    $ftpHosts = @(
        $(if ($sharedIp) { $sharedIp }),
        'ftp.kakiempat.com',
        $(if ($primary) { $primary })
    ) | Where-Object { $_ } | Select-Object -Unique

    $remoteDocroot = $targets[$name].docroot
    $fileCount = (Get-ChildItem $webRoot -Recurse -File).Count
    Write-Host "WinSCP sync $name -> $remoteDocroot ($fileCount file lokal, hosts: $($ftpHosts -join ', '))"

    Invoke-WinScpSyncLocalToRemote `
        -LocalPath $webRoot `
        -RemotePath $remoteDocroot `
        -UserName $user `
        -Password $pass `
        -HostNames $ftpHosts `
        -LibRoot $scriptLib
}

$buildTargets = if ($All) { @($targets.Keys) } else { @($Target) }

Write-Host '=== Kaki Empat v2 - deploy web ===' -ForegroundColor Cyan
Write-Host "Targets: $($buildTargets -join ', ')"
Write-Host "API: $ApiBaseUrl"
Write-Host "Web renderer: $WebRenderer (html = dart2js kecil; skwasm = --wasm; canvaskit = dart2js + Skia CDN)"
if ($buildTargets -contains 'owner') {
    Write-Host 'Money engine: owner.kakiempat.com (prioritas UX + stabilitas)' -ForegroundColor Yellow
}

if (-not $SkipAnalyze) {
    Write-Host 'flutter analyze ...'
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'flutter analyze gagal' }
}

if (-not $SkipBuild) {
    $buildArgs = @('build', 'web', '--release', '--tree-shake-icons') + $defines
    switch ($WebRenderer) {
        'skwasm' { $buildArgs += '--wasm' }
        'canvaskit' {
            # Flutter 3.41+: tidak ada --web-renderer; dart2js + CanvasKit via CDN (default engine).
            Write-Host 'canvaskit: dart2js build (CanvasKit dimuat dari CDN saat runtime)' -ForegroundColor DarkGray
        }
        default {
            # html: dart2js tanpa wasm — bundle paling ringan untuk dashboard owner/sitter.
            Write-Host 'html: dart2js tanpa --wasm (disarankan money engine)' -ForegroundColor DarkGray
        }
    }
    Write-Host "flutter $($buildArgs -join ' ') ..."
    flutter @buildArgs
    if ($LASTEXITCODE -ne 0) { throw 'flutter build web gagal' }
}

$webRoot = Join-Path $root 'build\web'
if (-not (Test-Path $webRoot)) { throw "Tidak ada $webRoot - jalankan build dulu." }

Write-Host ''
Write-Host 'Packaging per subdomain (SEO per target) ...'
foreach ($t in $buildTargets) {
    if ($Upload -and $SkipBuild) {
        # Hindari file lock saat build/web masih dipakai proses lain.
        $NoZip = $true
    }
    $pkg = New-DeployPackage -name $t -meta $targets[$t] -webRoot $webRoot -webRenderer $WebRenderer
    if ($Upload) {
        Invoke-WinScpUpload -name $t -webRoot $pkg.webRoot
    }
}

Write-Host ''
Write-Host 'Selesai. Upload ZIP ke docroot cPanel (extract isi ke root subdomain).' -ForegroundColor Cyan
Write-Host '  owner   -> owner.kakiempat.com   (money engine)'
Write-Host '  sitter  -> sitter.kakiempat.com'
Write-Host '  admin   -> admin.kakiempat.com'
Write-Host '  staging -> staging.kakiempat.com'
Write-Host '  www     -> public_html (www.kakiempat.com)'
Write-Host ''
Write-Host 'Contoh:'
Write-Host '  .\scripts\deploy_web.ps1 -Target owner -WebRenderer html'
Write-Host '  .\scripts\deploy_web.ps1 -All -SkipAnalyze -WebRenderer html'
Write-Host '  .\scripts\deploy_web.ps1 -Target owner -WebRenderer html -Upload'
Write-Host '  .\scripts\deploy_api_owner.ps1 -Upload   # hanya owner_v2.php (BFF parsial)'
Write-Host '  .\scripts\deploy_owner.ps1 -Layer both -WebRenderer html -Upload   # money engine'
