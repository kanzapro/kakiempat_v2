# Audit + perbaiki record DNS kakiempat.com via cPanel UAPI.
# Menambah A/CNAME yang hilang; idempotent jika zona sudah lengkap.
param(
    [switch]$Apply,
    [string]$Zone = 'kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

function Decode-B64([string]$b64) {
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b64))
}

function Invoke-Cpanel([string]$user, [string]$pass, [string]$uri) {
    curl.exe -sS -u "${user}:${pass}" $uri 2>&1
}

function Get-ZoneRecords($user, $pass, [string]$zone) {
    $raw = Invoke-Cpanel $user $pass "https://kakiempat.com:2083/execute/DNS/parse_zone?zone=$zone"
    $json = $raw | ConvertFrom-Json
    if ($json.status -ne 1) {
        throw "parse_zone gagal: $raw"
    }
    $map = @{}
    foreach ($r in $json.data) {
        if ($r.type -ne 'record') { continue }
        $name = $r.dname_raw.TrimEnd('.')
        $key = if ($name -eq $zone) { "$zone." } elseif ($name.EndsWith(".$zone")) {
            $name.Replace(".$zone", '')
        } else { $name }
        $vals = @($r.data_b64 | ForEach-Object { Decode-B64 $_ })
        if (-not $map.ContainsKey($key)) { $map[$key] = @() }
        $map[$key] += [PSCustomObject]@{
            Type = $r.record_type
            Values = $vals
        }
    }
    return $map
}

function Has-Record($map, [string]$name, [string]$type, [string]$expected) {
    if (-not $map.ContainsKey($name)) { return $false }
    foreach ($rec in $map[$name]) {
        if ($rec.Type -ne $type) { continue }
        $val = ($rec.Values -join ', ')
        if ($type -eq 'A' -and $val -eq $expected) { return $true }
        if ($type -eq 'CNAME' -and ($val -eq $expected -or $val -eq "$expected.")) { return $true }
    }
    return $false
}

function Add-ARecord($user, $pass, [string]$zone, [string]$name, [string]$ip, [int]$ttl = 14400) {
    $uri = "https://kakiempat.com:2083/execute/DNS/add_zone_record?domain=$zone&name=$name&type=A&address=$ip&ttl=$ttl"
    $raw = Invoke-Cpanel $user $pass $uri
    $json = $raw | ConvertFrom-Json
    return $json
}

function Add-CnameRecord($user, $pass, [string]$zone, [string]$name, [string]$target, [int]$ttl = 14400) {
    $uri = "https://kakiempat.com:2083/execute/DNS/add_zone_record?domain=$zone&name=$name&type=CNAME&cname=$target&ttl=$ttl"
    $raw = Invoke-Cpanel $user $pass $uri
    $json = $raw | ConvertFrom-Json
    return $json
}

$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
if (-not (Test-Path $credPath)) { throw "Missing $credPath" }
$ini = Get-Content $credPath -Raw
$user = Get-IniValue $ini 'cpanel' 'username'
$pass = Get-IniValue $ini 'cpanel' 'password'
$ip = Get-IniValue $ini 'cpanel' 'shared_ip'
if (-not $user -or -not $pass -or -not $ip) { throw 'cpanel username/password/shared_ip required' }

# Record wajib v2 — semua ke shared IP kecuali www (CNAME apex)
$required = @(
    @{ Name = "$Zone."; Type = 'A'; Value = $ip }
    @{ Name = 'www'; Type = 'CNAME'; Value = $Zone }
    @{ Name = 'api'; Type = 'A'; Value = $ip }
    @{ Name = 'www.api'; Type = 'A'; Value = $ip }
    @{ Name = 'owner'; Type = 'A'; Value = $ip }
    @{ Name = 'www.owner'; Type = 'A'; Value = $ip }
    @{ Name = 'sitter'; Type = 'A'; Value = $ip }
    @{ Name = 'www.sitter'; Type = 'A'; Value = $ip }
    @{ Name = 'admin'; Type = 'A'; Value = $ip }
    @{ Name = 'www.admin'; Type = 'A'; Value = $ip }
    @{ Name = 'staging'; Type = 'A'; Value = $ip }
    @{ Name = 'www.staging'; Type = 'A'; Value = $ip }
    @{ Name = 'ftp'; Type = 'A'; Value = $ip }
)

Write-Host "=== DNS audit: $Zone (IP $ip) ===" -ForegroundColor Cyan
$zoneMap = Get-ZoneRecords $user $pass $Zone
$report = @()
$fixes = @()

foreach ($req in $required) {
    $ok = Has-Record $zoneMap $req.Name $req.Type $req.Value
    $fqdn = if ($req.Name.EndsWith('.')) { $req.Name.TrimEnd('.') } else { "$($req.Name).$Zone" }
    $status = if ($ok) { 'OK' } else { 'MISSING' }
    Write-Host "$status  $($req.Type)  $fqdn  ->  $($req.Value)"
    $report += [PSCustomObject]@{ host = $fqdn; type = $req.Type; expected = $req.Value; status = $status }
    if (-not $ok) { $fixes += $req }
}

if ($fixes.Count -eq 0) {
    Write-Host "`nSemua record DNS v2 sudah benar." -ForegroundColor Green
} elseif (-not $Apply) {
    Write-Host "`n$($fixes.Count) record perlu ditambah. Jalankan dengan -Apply untuk memperbaiki." -ForegroundColor Yellow
} else {
    Write-Host "`nMenambah $($fixes.Count) record..." -ForegroundColor Yellow
    foreach ($req in $fixes) {
        $label = if ($req.Name.EndsWith('.')) { '@' } else { $req.Name }
        if ($req.Type -eq 'A') {
            $res = Add-ARecord $user $pass $Zone $label $req.Value
        } else {
            $res = Add-CnameRecord $user $pass $Zone $label $req.Value
        }
        if ($res.status -eq 1) {
            Write-Host "ADDED  $($req.Type)  $($req.Name)  ->  $($req.Value)" -ForegroundColor Green
        } else {
            $err = ($res.errors | Out-String).Trim()
            Write-Host "FAIL   $($req.Name): $err" -ForegroundColor Red
        }
    }
}

# Verifikasi resolusi lokal
Write-Host "`n=== Resolusi lokal ===" -ForegroundColor Cyan
$checkHosts = @(
    'www.kakiempat.com', 'api.kakiempat.com', 'www.api.kakiempat.com',
    'owner.kakiempat.com', 'www.owner.kakiempat.com',
    'sitter.kakiempat.com', 'www.sitter.kakiempat.com',
    'admin.kakiempat.com', 'www.admin.kakiempat.com',
    'staging.kakiempat.com', 'www.staging.kakiempat.com'
)
foreach ($h in $checkHosts) {
    try {
        $resolved = Resolve-DnsName -Name $h -Type A -DnsOnly -ErrorAction Stop |
            Where-Object { $_.IPAddress -and $_.IPAddress -notmatch ':' } |
            Select-Object -First 1 -ExpandProperty IPAddress
        $ok = ($resolved -eq $ip)
        Write-Host "$(if ($ok) { 'OK' } else { 'BAD' })  $h  ->  $resolved"
    } catch {
        Write-Host "ERR  $h  ->  $($_.Exception.Message)"
    }
}

$outDir = Join-Path $root 'artifacts'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$report | ConvertTo-Json -Depth 4 | Out-File (Join-Path $outDir 'dns_audit_v2.json') -Encoding utf8
Write-Host "`nLaporan: artifacts/dns_audit_v2.json"
