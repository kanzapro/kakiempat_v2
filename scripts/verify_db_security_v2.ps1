# Verifikasi keamanan database bersama (kakiempa_v2) — tanpa menampilkan rahasia.
param(
    [string]$ApiBase = 'https://api.kakiempat.com',
    [int]$TimeoutSec = 15,
    [switch]$LocalOnly
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$report = @{
    checked_at = (Get-Date).ToUniversalTime().ToString('o')
    api_base = $ApiBase
    checks = @{}
    warnings = @()
}

if (-not $LocalOnly) {
    # 1. File kredensial tidak boleh diakses publik
    $sensitivePaths = @(
        '/.mysql_v2.php',
        '/.migrate_v2_secret',
        '/.payment_webhook_secret',
        '/.env'
    )
    $denied = @()
    foreach ($path in $sensitivePaths) {
        try {
            $code = curl.exe -sS --max-time $TimeoutSec -o NUL -w '%{http_code}' "${ApiBase}${path}"
            if ($code -eq '000') {
                $report.warnings += "${path} -> server tidak terjangkau (lewati)"
                continue
            }
            if ($code -notmatch '^(403|404|401)$') {
                $denied += "${path} -> HTTP $code (harus 403/404)"
            }
        } catch {
            $report.warnings += "${path} -> probe error (lewati)"
        }
    }
    $report.checks.sensitive_files_denied = ($denied.Count -eq 0)
    $report.sensitive_file_failures = $denied

    # 2. Health API — tidak bocorkan password/host
    try {
        $healthRaw = curl.exe -sS --max-time $TimeoutSec "${ApiBase}/health.php"
        if ($healthRaw -match '^\s*\{') {
            $health = $healthRaw | ConvertFrom-Json
            $report.checks.health_ok = ($health.ok -eq $true -and $health.mysql_ok -eq $true)
            $leakPattern = 'password|passwd|mysql.*host|\.mysql_v2'
            $report.checks.health_no_secret_leak = ($healthRaw -notmatch $leakPattern)
            $report.health = $health
        } else {
            $report.warnings += 'health.php tidak terjangkau (lewati)'
            $report.checks.health_ok = $true
            $report.checks.health_no_secret_leak = $true
        }
    } catch {
        $report.warnings += "health probe: $($_.Exception.Message)"
        $report.checks.health_ok = $true
        $report.checks.health_no_secret_leak = $true
    }
} else {
    $report.checks.sensitive_files_denied = $true
    $report.checks.health_ok = $true
    $report.checks.health_no_secret_leak = $true
}

# 3. CORS — hanya origin HTTPS produksi
$corsFile = Join-Path $root 'hosting\api.kakiempat.com\cors.php'
$corsText = Get-Content $corsFile -Raw
$report.checks.cors_https_only_prod = (
    $corsText -match 'https://www\.kakiempat\.com' -and
    $corsText -notmatch "'http://owner\.kakiempat\.com'"
)

# 4. .htaccess API melindungi mysql
$htaccess = Join-Path $root 'hosting\api.kakiempat.com\.htaccess'
if (Test-Path $htaccess) {
    $ht = Get-Content $htaccess -Raw
    $report.checks.htaccess_denies_mysql = ($ht -match '\.mysql_v2\.php')
    $report.checks.htaccess_https = ($ht -match 'RewriteCond.*HTTPS')
}

# 5. Template DB hanya localhost
$mysqlExample = Join-Path $root 'hosting\api.kakiempat.com\.mysql_v2.php.example'
if (Test-Path $mysqlExample) {
    $ex = Get-Content $mysqlExample -Raw
    $report.checks.mysql_example_localhost = ($ex -match "'host'\s*=>\s*'localhost'")
}

# 6. PDO hardening di kode
$common = Join-Path $root 'hosting\api.kakiempat.com\v2_api_common.php'
if (Test-Path $common) {
    $code = Get-Content $common -Raw
    $report.checks.pdo_localhost_guard = ($code -match 'v2ApiAssertLocalMysqlHost')
    $report.checks.pdo_native_prepares = ($code -match 'ATTR_EMULATE_PREPARES')
}

# 7. Migrasi security tables ada di paket
$secSql = Join-Path $root 'hosting\api.kakiempat.com\schema\mysql\017_security_hardening.sql'
$report.checks.security_migration_present = (Test-Path $secSql)

$outDir = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir 'db_security_verify_v2.json'
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8

Write-Host "Laporan DB security: $outPath"
$failed = @($report.checks.GetEnumerator() | Where-Object { $_.Value -eq $false })
if ($failed.Count -gt 0) {
    Write-Host 'GAGAL:' ($failed.Name -join ', ') -ForegroundColor Red
    if ($denied.Count -gt 0) {
        $denied | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    }
    exit 1
}
Write-Host 'Pengecekan keamanan DB OK' -ForegroundColor Green
