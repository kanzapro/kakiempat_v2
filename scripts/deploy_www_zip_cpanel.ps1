# Upload www-deploy.zip + extract script ke public_html, ekstrak ke www.kakiempat.com.
param(
    [string]$ZipPath = '',
    [switch]$SkipUpload
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $root 'scripts\lib\cpanel_upload.ps1')

if (-not $ZipPath) {
    $ZipPath = Join-Path $root 'build\release_v2\www-deploy.zip'
}
$extractPhp = Join-Path $root 'build\deploy-www-release-v2-extract.php'
$publicHtml = '/home/kakiempa/public_html'

if (-not (Test-Path $ZipPath)) { throw "ZIP tidak ada: $ZipPath" }
if (-not (Test-Path $extractPhp)) { throw "Extract script tidak ada: $extractPhp" }

$creds = Get-HostingCpanelCredentials -ProjectRoot $root
$user = $creds.User
$pass = $creds.Pass
$panelHost = $creds.PanelHost

function Get-CpanelSecret {
    param([hashtable]$Credentials)
    $dirs = @('/home/kakiempa/public_html', '/home/kakiempa/public_html/api')
    $files = @('.kakiempat_deploy_secret', '.kakiempat_media_secret')
    foreach ($dir in $dirs) {
        foreach ($file in $files) {
            $url = "https://$($Credentials.PanelHost):2083/execute/Fileman/get_file_content?dir=$([uri]::EscapeDataString($dir))&file=$file"
            if ($Credentials.Token) {
                $out = curl.exe -sS --connect-timeout 30 -H "Authorization: cpanel $($Credentials.User):$($Credentials.Token)" $url 2>&1
            } else {
                $out = curl.exe -sS --connect-timeout 30 -u "$($Credentials.User):$($Credentials.Pass)" $url 2>&1
            }
            if ($out -match '"status":1' -and $out -match '"content":"([^"]+)"') {
                $raw = $Matches[1] -replace '\\n', "`n" -replace '\\r', ''
                $v = ($raw -split "`n" | Select-Object -First 1).Trim()
                if ($v) { return $v }
            }
        }
    }
    return $null
}

if (-not $SkipUpload) {
    $zipMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Host "Upload www-deploy.zip ($zipMb MB) -> $publicHtml ..." -ForegroundColor Cyan
    Send-CpanelFile -Credentials $creds -LocalPath $ZipPath -RemoteDir $publicHtml -RemoteFile 'www-deploy.zip' -MaxRetry 8 | Out-Null
    Write-Host '[OK] www-deploy.zip'

    Write-Host 'Upload deploy-www-release-v2-extract.php ...' -ForegroundColor Cyan
    Send-CpanelFile -Credentials $creds -LocalPath $extractPhp -RemoteDir $publicHtml -RemoteFile 'deploy-www-release-v2-extract.php' | Out-Null
    Write-Host '[OK] deploy-www-release-v2-extract.php'
}

$secret = Get-CpanelSecret -Credentials $creds
if (-not $secret) { throw 'Deploy secret tidak ditemukan di public_html (.kakiempat_deploy_secret / .kakiempat_media_secret)' }

Write-Host 'Trigger server-side extract ...' -ForegroundColor Cyan
$urls = @(
    "https://www.kakiempat.com/deploy-www-release-v2-extract.php?run=1&key=$([uri]::EscapeDataString($secret))",
    "https://kakiempat.com/deploy-www-release-v2-extract.php?run=1&key=$([uri]::EscapeDataString($secret))"
)
$ok = $false
foreach ($u in $urls) {
    $out = curl.exe -sS -L --connect-timeout 300 --max-time 600 -H 'Accept: text/plain' $u 2>&1
    Write-Host $out
    if ($out -match 'DONE deploy-www-release-v2-extract') {
        $ok = $true
        break
    }
}
if (-not $ok) { throw 'Extract gagal — cek output di atas' }

Write-Host 'Verifikasi HTTP ...' -ForegroundColor Cyan
$idx = curl.exe -sS -o NUL -w '%{http_code}' 'https://www.kakiempat.com/index.html'
$main = curl.exe -sS -o NUL -w '%{http_code}' 'https://www.kakiempat.com/main.dart.js'
Write-Host "  index.html HTTP $idx"
Write-Host "  main.dart.js HTTP $main"
if ($idx -ne '200' -or $main -ne '200') { throw 'File utama tidak dapat diakses via HTTPS' }

Write-Host 'Deploy WWW selesai.' -ForegroundColor Green
