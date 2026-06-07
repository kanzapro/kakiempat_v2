# Verifikasi pra-rilis: audit kode, CORS, health API (tanpa menampilkan secret).
param(
    [string]$ApiBase = 'https://api.kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$report = @{
    checked_at = (Get-Date).ToUniversalTime().ToString('o')
    api_base = $ApiBase
    checks = @{}
    warnings = @()
}

function Test-PatternAbsent {
    param([string]$Path, [string]$Pattern, [string]$Label)
    $hits = @()
    if (Test-Path $Path) {
        $hits = Get-ChildItem -Path $Path -Recurse -File -Filter '*.dart' -ErrorAction SilentlyContinue |
            Select-String -Pattern $Pattern -SimpleMatch:$false
    }
    return @{ label = $Label; ok = ($hits.Count -eq 0); count = $hits.Count }
}

# 1. Tidak ada Firebase/Supabase di lib + pubspec
$fb = Test-PatternAbsent (Join-Path $root 'lib') 'import.*firebase|firebase_core|firebase_messaging|package:supabase' 'no_firebase_lib'
$report.checks.no_firebase_lib = $fb.ok
if (-not $fb.ok) { $report.warnings += 'firebase/supabase ditemukan di lib/' }

$pub = Get-Content (Join-Path $root 'pubspec.yaml') -Raw
$report.checks.no_firebase_pubspec = ($pub -notmatch 'firebase|supabase')
if (-not $report.checks.no_firebase_pubspec) { $report.warnings += 'firebase/supabase di pubspec.yaml' }

# 2. CORS origins
$corsFile = Join-Path $root 'hosting\api.kakiempat.com\cors.php'
$corsText = Get-Content $corsFile -Raw
$requiredOrigins = @(
    'https://www.kakiempat.com',
    'https://kakiempat.com',
    'https://owner.kakiempat.com',
    'https://sitter.kakiempat.com',
    'https://admin.kakiempat.com',
    'https://staging.kakiempat.com'
)
$missingCors = @($requiredOrigins | Where-Object { $corsText -notmatch [regex]::Escape($_) })
$report.checks.cors_all_domains = ($missingCors.Count -eq 0)
$report.cors_missing = $missingCors

# 3. File konfigurasi sensitif di gitignore
$gitignore = Get-Content (Join-Path $root '.gitignore') -Raw -ErrorAction SilentlyContinue
$report.checks.gitignore_env = ($gitignore -match '\.env')
$report.checks.gitignore_credentials = ($gitignore -match 'hosting\.credentials|\.mysql_v2')

# 4. .htaccess API
$htaccess = Join-Path $root 'hosting\api.kakiempat.com\.htaccess'
$report.checks.htaccess_exists = (Test-Path $htaccess)
if (Test-Path $htaccess) {
    $ht = Get-Content $htaccess -Raw
    $report.checks.htaccess_denies_mysql = ($ht -match '\.mysql_v2\.php')
    $report.checks.htaccess_https = ($ht -match 'RewriteCond.*HTTPS')
}

# 5. Health API
try {
    $health = curl.exe -sS "${ApiBase}/health.php"
    $hj = $health | ConvertFrom-Json
    $report.checks.health_ok = ($hj.ok -eq $true -and $hj.mysql_ok -eq $true)
    $report.health = $hj
} catch {
    $report.checks.health_ok = $false
    $report.health_error = $_.Exception.Message
}

# 6. Index API
try {
    $idx = curl.exe -sS "${ApiBase}/index.php"
    $ij = $idx | ConvertFrom-Json
    $report.checks.index_ok = ($ij.ok -eq $true)
} catch {
    $report.checks.index_ok = $false
}

# 7. CORS preflight owner
try {
    $preflight = curl.exe -sS -o NUL -w '%{http_code}' -X OPTIONS `
        -H 'Origin: https://owner.kakiempat.com' `
        -H 'Access-Control-Request-Method: GET' `
        "${ApiBase}/auth_v2.php?action=validate_token"
    $report.checks.cors_preflight_owner = ($preflight -eq '204' -or $preflight -eq '200')
    $report.cors_preflight_code = $preflight
} catch {
    $report.checks.cors_preflight_owner = $false
}

$outDir = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir 'release_verify_v2.json'
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8

Write-Host "Laporan: $outPath"
$failed = @($report.checks.GetEnumerator() | Where-Object { $_.Value -eq $false })
if ($failed.Count -gt 0) {
    Write-Host 'GAGAL:' ($failed.Name -join ', ') -ForegroundColor Red
    exit 1
}
Write-Host 'Semua pengecekan OK' -ForegroundColor Green
