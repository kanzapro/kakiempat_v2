# Verifikasi SSL/HTTPS — domain utama + wildcard subdomain (*.kakiempat.com)
param(
    [int]$TimeoutSec = 15
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$hosts = @(
    @{ host = 'kakiempat.com'; label = 'apex' },
    @{ host = 'www.kakiempat.com'; label = 'www' },
    @{ host = 'owner.kakiempat.com'; label = 'owner' },
    @{ host = 'sitter.kakiempat.com'; label = 'sitter' },
    @{ host = 'admin.kakiempat.com'; label = 'admin' },
    @{ host = 'staging.kakiempat.com'; label = 'staging' },
    @{ host = 'api.kakiempat.com'; label = 'api' },
    @{ host = 'www.api.kakiempat.com'; label = 'api_www' }
)

$report = @{
    checked_at = (Get-Date).ToUniversalTime().ToString('o')
    hosts = @()
    ok = $true
}

foreach ($entry in $hosts) {
    $h = $entry.host
    $row = @{
        host = $h
        label = $entry.label
        https_ok = $false
        http_redirects_https = $false
        hsts = $false
        tls_version = $null
        cert_expires = $null
        errors = @()
    }

    $httpsCode = curl.exe -sS --max-time $TimeoutSec -o NUL -w '%{http_code}' "https://$h/" 2>$null
    if ($LASTEXITCODE -ne 0 -or $httpsCode -eq '000') {
        $row.errors += "HTTPS unreachable (curl exit $LASTEXITCODE, code $httpsCode)"
    } else {
        $row.https_ok = ($httpsCode -match '^(200|301|302|304)$')
        if (-not $row.https_ok) {
            $row.errors += "HTTPS status $httpsCode"
        }
    }

    $httpOut = curl.exe -sS --max-time $TimeoutSec -I "http://$h/" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        $row.errors += "HTTP probe failed (curl exit $LASTEXITCODE)"
    } else {
        $loc = ($httpOut | Select-String -Pattern '^location:\s*(.+)$' -CaseSensitive:$false |
            Select-Object -First 1).Matches.Groups[1].Value.Trim()
        $row.http_redirects_https = ($loc -match '^https://')
        if (-not $row.http_redirects_https) {
            $row.errors += 'HTTP tidak redirect ke HTTPS'
        }
    }

    $verbose = curl.exe -sS --max-time $TimeoutSec -I -v "https://$h/" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        $row.errors += "TLS inspect failed (curl exit $LASTEXITCODE)"
    } else {
        $row.hsts = ($verbose -imatch 'strict-transport-security')
        if (-not $row.hsts) {
            $row.errors += 'Header HSTS tidak ditemukan'
        }
        if ($verbose -match 'SSL connection using ([^\r\n]+)') {
            $row.tls_version = $Matches[1].Trim()
        }
        if ($verbose -match 'expire date:\s*([^\r\n]+)') {
            $row.cert_expires = $Matches[1].Trim()
        }
    }

    $row.ok = ($row.errors.Count -eq 0)
    if (-not $row.ok) { $report.ok = $false }
    $report.hosts += $row
}

$outDir = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir 'ssl_verify_v2.json'
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8

Write-Host "Laporan SSL: $outPath"
foreach ($r in $report.hosts) {
    $status = if ($r.ok) { 'OK' } else { 'GAGAL' }
    $color = if ($r.ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1}" -f $status, $r.host) -ForegroundColor $color
    if ($r.errors.Count -gt 0) {
        $r.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }
}

if (-not $report.ok) {
    Write-Host ''
    Write-Host 'SSL belum lengkap. Di cPanel: SSL/TLS Status -> Run AutoSSL, atau pasang wildcard *.kakiempat.com.' -ForegroundColor Cyan
    exit 1
}
Write-Host 'Semua host HTTPS OK' -ForegroundColor Green
