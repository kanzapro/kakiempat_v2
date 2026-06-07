# SEO artifacts per subdomain — dipakai deploy_web.ps1, build_release_v2.ps1, dll.
function Apply-WebSeoArtifacts {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('www', 'owner', 'sitter', 'admin', 'staging')]
        [string]$Target,
        [Parameter(Mandatory)]
        [string]$DestDir,
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $shared = Join-Path $ProjectRoot 'hosting\web_shared'
    $htaccessSrc = Join-Path $shared '.htaccess'
    if (Test-Path $htaccessSrc) {
        Copy-Item $htaccessSrc (Join-Path $DestDir '.htaccess') -Force
    }

    if ($Target -eq 'www') {
        Copy-Item (Join-Path $shared 'robots-www.txt') (Join-Path $DestDir 'robots.txt') -Force
        Copy-Item (Join-Path $shared 'sitemap.xml') (Join-Path $DestDir 'sitemap.xml') -Force
        return
    }

    Copy-Item (Join-Path $shared 'robots-noindex.txt') (Join-Path $DestDir 'robots.txt') -Force
    $sitemapPath = Join-Path $DestDir 'sitemap.xml'
    if (Test-Path $sitemapPath) { Remove-Item $sitemapPath -Force }

    $indexPath = Join-Path $DestDir 'index.html'
    if (-not (Test-Path $indexPath)) { return }

    $html = Get-Content $indexPath -Raw -Encoding UTF8
    if ($html -notmatch 'name="robots"') {
        $html = $html -replace '(<meta charset="UTF-8">)', "`$1`n  <meta name=`"robots`" content=`"noindex, nofollow`">"
    }

    $titles = @{
        owner   = 'Kaki Empat - Pemilik Hewan'
        sitter  = 'Kaki Empat - Pengasuh Hewan'
        admin   = 'Kaki Empat - Panel Admin'
        staging = 'Kaki Empat - Staging'
    }
    $title = $titles[$Target]
    if ($title) {
        $html = $html -replace '<title>[^<]*</title>', "<title>$title</title>"
    }

    Set-Content -Path $indexPath -Value $html -Encoding UTF8 -NoNewline
}

function New-TargetWebRoot {
    param(
        [Parameter(Mandatory)]
        [string]$SourceDir,
        [Parameter(Mandatory)]
        [ValidateSet('www', 'owner', 'sitter', 'admin', 'staging')]
        [string]$Target,
        [Parameter(Mandatory)]
        [string]$ProjectRoot,
        [string]$StagingDir
    )

    if (-not $StagingDir) {
        $StagingDir = Join-Path $ProjectRoot "build\deploy_staging\$Target"
    }
    if (Test-Path $StagingDir) {
        Remove-Item $StagingDir -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null
    Copy-Item -Path (Join-Path $SourceDir '*') -Destination $StagingDir -Recurse -Force
    Apply-WebSeoArtifacts -Target $Target -DestDir $StagingDir -ProjectRoot $ProjectRoot
    return $StagingDir
}
